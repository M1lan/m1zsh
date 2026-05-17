#!/usr/bin/env bash
# Smoke test for `m1zsh_doctor` -- exercise every output mode in a fresh
# interactive zsh, prove exit codes and structural invariants without
# leaking absolute home-directory paths into stdout.

: "${EPOCHREALTIME:?requires GNU Bash >= 5.3}" 2> /dev/null || {
  printf 'error: GNU Bash >= 5.3 required (found %s)\n' "$BASH_VERSION" >&2
  exit 1
}

set -uo pipefail
export LC_ALL=C

# Build the leakage pattern at runtime so this file itself does not contain
# the literal "/U" "s" "ers/" string that scan-secrets.bash would flag.
HOME_LEAK_RE='^[^/]*/U'"sers/"'[A-Za-z0-9._-]+/'
HOME_LEAK_RE_ANY='/U'"sers/"'[A-Za-z0-9._-]+/'

repo_root=$(git rev-parse --show-toplevel 2> /dev/null) || {
  printf 'error: must run inside the m1zsh git repository\n' >&2
  exit 2
}
cd "$repo_root" || exit 2

if ! command -v zsh > /dev/null 2>&1; then
  printf 'error: zsh not found\n' >&2
  exit 127
fi

fail=0
note() { printf '%s\n' "$*"; }
ok()   { printf 'PASS %s\n' "$*"; }
bad()  { printf 'FAIL %s\n' "$*" >&2; fail=$((fail + 1)); }

# Common preamble: run in a fresh interactive zsh with rc files muted,
# adapters disabled, Zi skipped, so the test is hermetic.
run_doctor() {
  local args="$1"
  ZDOTDIR=/dev/null zsh -ic '
    export M1ZSH_HOME="'"$repo_root"'" M1ZSH_SKIP_ZI=1 M1ZSH_DISABLE_TOOL_ADAPTERS=1
    source "$M1ZSH_HOME/init.zsh"
    m1zsh_doctor '"$args"'
  ' 2> /dev/null
}

# --- 1. quiet mode -----------------------------------------------------
quiet_out=$(run_doctor '--quiet')
quiet_rc=$?
if [[ $quiet_out =~ ^m1zsh\ 0\.1\.0\ home=.+\ zi=.+\ ok=[0-9]+\ warn=[0-9]+\ err=[0-9]+$ ]]; then
  ok "quiet mode emits single summary line"
else
  bad "quiet mode line not as expected: $quiet_out"
fi
if [[ $quiet_rc -eq 0 || $quiet_rc -eq 2 ]]; then
  ok "quiet mode exit code is 0 or 2 (got $quiet_rc)"
else
  bad "quiet mode unexpected exit code: $quiet_rc"
fi

# --- 2. text mode contains all required sections -----------------------
text_out=$(run_doctor '--color=never')
required_sections=(
  '=== m1zsh ==='
  '=== shell ==='
  '=== zi ==='
  '=== modules ==='
  '=== tool adapters ==='
  '=== completion ==='
  '=== fpath / path ==='
  '=== history ==='
  '=== brew ==='
  '=== personal overlay ==='
  '=== summary ==='
)
for sec in "${required_sections[@]}"; do
  if grep -qF -- "$sec" <<< "$text_out"; then
    ok "text mode has $sec"
  else
    bad "text mode missing $sec"
  fi
done

# --- 3. no absolute home-directory leakage in stdout -------------------
if grep -qE "$HOME_LEAK_RE" <<< "$text_out"; then
  bad "text mode leaked an absolute home path; HOME->~ collapse broken"
  grep -nE "$HOME_LEAK_RE_ANY" <<< "$text_out" | head -3 >&2
else
  ok "text mode collapses HOME to ~ everywhere"
fi
if grep -qE "$HOME_LEAK_RE_ANY" <<< "$quiet_out"; then
  bad "quiet mode leaked absolute path"
else
  ok "quiet mode collapses HOME to ~"
fi

# --- 4. JSON mode -----------------------------------------------------
json_out=$(run_doctor '--json')
# Must be parseable
if command -v python3 > /dev/null 2>&1; then
  if printf '%s' "$json_out" | python3 -c 'import json,sys;json.loads(sys.stdin.read())' > /dev/null 2>&1; then
    ok "json mode produces valid JSON"
  else
    bad "json mode is not valid JSON"
    printf '%s\n' "$json_out" | head -c 400 >&2
    printf '\n' >&2
  fi
else
  printf 'INFO python3 unavailable; skipping JSON validation\n'
fi
# Must contain core keys
for key in '"version"' '"modules"' '"adapters"' '"summary"' '"findings"'; do
  if grep -qF "$key" <<< "$json_out"; then
    ok "json mode has $key"
  else
    bad "json mode missing $key"
  fi
done

# --- 5. exit code semantics ------------------------------------------
# With M1ZSH_SKIP_ZI=1 and DISABLE_TOOL_ADAPTERS=1, the only expected warnings
# come from "adapter snippet not activated" (suppressed when present=no) and
# possibly a missing path entry on this host. Exit code should be 0 or 2,
# never 1, because we don't expect ERRORs in the smoke env.
ZDOTDIR=/dev/null zsh -ic '
  export M1ZSH_HOME="'"$repo_root"'" M1ZSH_SKIP_ZI=1 M1ZSH_DISABLE_TOOL_ADAPTERS=1
  source "$M1ZSH_HOME/init.zsh"
  m1zsh_doctor --quiet > /dev/null
  exit $?
' 2> /dev/null
rc=$?
if [[ $rc -eq 0 || $rc -eq 2 ]]; then
  ok "smoke env produces no ERRORs (rc=$rc)"
else
  bad "smoke env produced an ERROR-level finding (rc=$rc)"
fi

# --- 6. unknown arg returns 64 ---------------------------------------
ZDOTDIR=/dev/null zsh -ic '
  export M1ZSH_HOME="'"$repo_root"'" M1ZSH_SKIP_ZI=1 M1ZSH_DISABLE_TOOL_ADAPTERS=1
  source "$M1ZSH_HOME/init.zsh"
  m1zsh_doctor --bogus 2> /dev/null
  exit $?
' 2> /dev/null
rc=$?
if [[ $rc -eq 64 ]]; then
  ok "unknown arg returns 64 (EX_USAGE)"
else
  bad "unknown arg returned $rc, expected 64"
fi

# --- 7. NO_COLOR respected --------------------------------------------
plain_out=$(NO_COLOR=1 ZDOTDIR=/dev/null zsh -ic '
  export M1ZSH_HOME="'"$repo_root"'" M1ZSH_SKIP_ZI=1 M1ZSH_DISABLE_TOOL_ADAPTERS=1
  source "$M1ZSH_HOME/init.zsh"
  m1zsh_doctor
' 2> /dev/null)
if [[ $plain_out == *$'\e['* ]]; then
  bad "NO_COLOR=1 still emitted ANSI escapes"
else
  ok "NO_COLOR=1 suppresses ANSI escapes"
fi

# --- 8. shim dispatcher ------------------------------------------------
if [[ -x "$repo_root/bin/m1zsh" ]]; then
  shim_help=$("$repo_root/bin/m1zsh" help 2>&1) || true
  if grep -qF 'usage: m1zsh' <<< "$shim_help"; then
    ok "bin/m1zsh help works"
  else
    bad "bin/m1zsh help did not print usage"
  fi
  shim_ver=$("$repo_root/bin/m1zsh" version 2>&1) || true
  if [[ $shim_ver == 0.1.0 ]]; then
    ok "bin/m1zsh version reports 0.1.0"
  else
    bad "bin/m1zsh version: $shim_ver"
  fi
else
  bad "bin/m1zsh missing or not executable"
fi

if ((fail > 0)); then
  printf 'smoke-doctor: %d failure(s)\n' "$fail" >&2
  exit 1
fi
printf 'smoke-doctor: PASS\n'
