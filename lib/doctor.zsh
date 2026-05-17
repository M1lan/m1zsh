# m1zsh_doctor — health-check report for an active m1zsh shell.
#
# Usage:
#   m1zsh_doctor [--text|--json|--quiet] [--color=auto|always|never]
#                [--no-color] [-h|--help]
#
# Modes:
#   text  (default) — sectioned, optionally coloured report
#   json            — single-line JSON object suitable for piping
#   quiet           — one-line summary; exit code carries the verdict
#
# Exit codes:
#   0  — every check passed
#   1  — at least one ERROR
#   2  — only WARNs, no ERRORs
#  64  — unrecognised flag (sysexits EX_USAGE)
# 127  — internal: required helper missing
#
# Constraints:
#   * no_unset safe — every parameter expansion uses ${var:-} or ${+var}
#   * each check is isolated; a single failure never aborts the report
#   * collapses $HOME -> ~ in every emitted path
#   * ANSI colour iff stdout is a tty AND NO_COLOR is unset
#   * relies only on stock zsh + git (git is optional)

zmodload zsh/datetime 2>/dev/null
zmodload -F zsh/stat b:zstat 2>/dev/null

# ---------- private helpers ----------

# Collapse $HOME to ~ in a path. Safe under no_unset.
_m1zsh_doctor_tildify() {
  emulate -L zsh
  local p=${1-}
  if [[ -n ${HOME-} && -n $p && $p == ${HOME}* ]]; then
    p="~${p#$HOME}"
  fi
  print -r -- "$p"
}

# Modification time in epoch seconds, BSD/GNU/zsh portable.
_m1zsh_doctor_mtime() {
  emulate -L zsh
  local f=${1-} mt=0
  [[ -e $f ]] || { print -r -- 0; return 0; }
  if (( ${+functions[zstat]} )); then
    mt=$(zstat -L +mtime -- "$f" 2>/dev/null) || mt=0
  fi
  if [[ -z $mt || $mt == 0 ]]; then
    mt=$(stat -f %m -- "$f" 2>/dev/null) || mt=
    [[ -z $mt ]] && mt=$(stat -c %Y -- "$f" 2>/dev/null) || true
    [[ -z $mt ]] && mt=0
  fi
  print -r -- "$mt"
}

_m1zsh_doctor_filesize() {
  emulate -L zsh
  local f=${1-} sz=0
  [[ -e $f ]] || { print -r -- 0; return 0; }
  sz=$(stat -f %z -- "$f" 2>/dev/null) || sz=
  [[ -z $sz ]] && sz=$(stat -c %s -- "$f" 2>/dev/null) || true
  [[ -z $sz ]] && sz=0
  print -r -- "$sz"
}

# Minimal JSON string escaper (handles \, ", control chars).
_m1zsh_doctor_json_str() {
  emulate -L zsh
  local s=${1-}
  s=${s//\\/\\\\}
  s=${s//\"/\\\"}
  s=${s//$'\n'/\\n}
  s=${s//$'\r'/\\r}
  s=${s//$'\t'/\\t}
  print -rn -- "\"$s\""
}

# Probe whether the tool that a given adapter is meant to integrate is
# actually installed. Returns "yes" / "no".
_m1zsh_doctor_adapter_present() {
  emulate -L zsh
  local tool=${1-}
  case $tool in
    atuin)  (( ${+commands[atuin]} )) && { print yes; return; } ;;
    bun)    { (( ${+commands[bun]} )) || [[ -r "${BUN_INSTALL:-${HOME:-}/.bun}/_bun" ]]; } && { print yes; return; } ;;
    fzf)    (( ${+commands[fzf]} )) && { print yes; return; } ;;
    ghcup)  { (( ${+commands[ghcup]} )) || [[ -r "${HOME:-}/.ghcup/env" ]]; } && { print yes; return; } ;;
    goenv)  (( ${+commands[goenv]} )) && { print yes; return; } ;;
    mise)   (( ${+commands[mise]} )) && { print yes; return; } ;;
    sdkman) [[ -r "${SDKMAN_DIR:-${HOME:-}/.sdkman}/bin/sdkman-init.sh" ]] && { print yes; return; } ;;
    zoxide) (( ${+commands[zoxide]} )) && { print yes; return; } ;;
    *)      (( ${+commands[$tool]} )) && { print yes; return; } ;;
  esac
  print no
}

# ---------- main ----------

m1zsh_doctor() {
  emulate -L zsh
  setopt no_unset pipe_fail no_aliases

  local mode=text
  local force_color=auto
  local arg
  for arg in "$@"; do
    case $arg in
      --text)          mode=text ;;
      --json)          mode=json ;;
      --quiet|-q)      mode=quiet ;;
      --color=auto)    force_color=auto ;;
      --color=always)  force_color=always ;;
      --color=never|--no-color) force_color=never ;;
      -h|--help)
        cat <<'EOF'
usage: m1zsh_doctor [--text|--json|--quiet] [--color=auto|always|never]

Reports the health of the currently loaded m1zsh installation.
Exit code is 0 (ok), 1 (errors), or 2 (warnings only).
EOF
        return 0
        ;;
      *) print -u2 -- "m1zsh_doctor: unknown argument: $arg"; return 64 ;;
    esac
  done

  local use_color=0
  case $force_color in
    always) use_color=1 ;;
    never)  use_color=0 ;;
    auto)   [[ -t 1 && -z ${NO_COLOR:-} ]] && use_color=1 ;;
  esac

  local C_RESET='' C_RED='' C_YEL='' C_GRN='' C_CYAN='' C_DIM=''
  if (( use_color )); then
    # Prefer tput over raw ANSI escapes (per project house style); fall back
    # to %F{...} prompt expansion via `print -P` if terminfo is missing.
    if (( ${+commands[tput]} )); then
      C_RESET=$(tput sgr0 2>/dev/null)
      C_RED=$(tput setaf 1 2>/dev/null)
      C_GRN=$(tput setaf 2 2>/dev/null)
      C_YEL=$(tput setaf 3 2>/dev/null)
      C_CYAN=$(tput setaf 6 2>/dev/null)
      C_DIM=$(tput dim 2>/dev/null)
    fi
    # If tput failed (e.g. TERM unknown), use zsh prompt expansion.
    if [[ -z $C_RESET ]]; then
      C_RESET=${(%):-%f}
      C_RED=${(%):-%F{red}}
      C_GRN=${(%):-%F{green}}
      C_YEL=${(%):-%F{yellow}}
      C_CYAN=${(%):-%F{cyan}}
      C_DIM=''
    fi
  fi

  # ---- finding accumulator (level|category|message|recommendation) ----
  local -a findings
  local -i errs=0 warns=0 oks=0
  _m1zsh_doctor_note() {
    local lvl=$1 cat=$2 msg=$3 rec=${4:-}
    findings+=("${lvl}|${cat}|${msg}|${rec}")
    case $lvl in
      error) (( errs++ )) ;;
      warn)  (( warns++ )) ;;
      ok)    (( oks++ )) ;;
    esac
  }

  # ---- 1. m1zsh version + home + sha ----
  local home=${M1ZSH_HOME:-}
  local version='unknown'
  if [[ -n $home && -r "$home/VERSION" ]]; then
    version=${"$(<$home/VERSION)"%%[$'\n\r ']*}
    [[ -z $version ]] && version='unknown'
  else
    _m1zsh_doctor_note warn meta "VERSION file missing" "create ${home:-\$M1ZSH_HOME}/VERSION"
  fi
  local sha=''
  if [[ -n $home && -e "$home/.git" ]] && (( ${+commands[git]} )); then
    sha=$(command git -C "$home" rev-parse --short HEAD 2>/dev/null) || sha=''
  fi
  [[ -n $home ]] && _m1zsh_doctor_note ok meta "M1ZSH_HOME=${home}"

  # ---- 2. shell info ----
  local zver=${ZSH_VERSION:-unknown}
  local zpath
  if [[ -n ${commands[zsh]:-} ]]; then
    zpath=${commands[zsh]}
  else
    zpath=${ZSH_NAME:-zsh}
  fi

  # ---- 3. Zi status ----
  local zi_status='absent'
  if [[ ${M1ZSH_SKIP_ZI:-0} == 1 ]]; then
    zi_status='skipped'
    _m1zsh_doctor_note ok zi "Zi skipped via M1ZSH_SKIP_ZI=1"
  elif (( ${+functions[zi]} )); then
    zi_status='loaded'
    _m1zsh_doctor_note ok zi "Zi loaded"
  else
    _m1zsh_doctor_note warn zi "Zi not loaded" "install Zi (https://wiki.zshell.dev) or set M1ZSH_SKIP_ZI=1"
  fi

  # ---- 4. per-module sentinels ----
  local -a module_names=(
    00-env 10-interactive 20-zi 30-completion 40-prompt
    50-plugins 60-aliases 70-tools 90-personal
  )
  local -a module_rows
  local m guard
  for m in $module_names; do
    if (( ${+functions[m1zsh_guard_var]} )); then
      guard=$(m1zsh_guard_var "modules/${m}.zsh")
    else
      guard="_M1ZSH_LOADED_modules_${m//-/_}_zsh"
    fi
    if (( ${(P)+guard} )) && [[ ${(P)guard} == 1 ]]; then
      module_rows+=("${m}=hit")
    else
      module_rows+=("${m}=miss")
      _m1zsh_doctor_note warn module "module ${m} not loaded (guard ${guard} unset)"
    fi
  done

  # ---- 5. tool adapters ----
  local -a adapter_rows
  local adir="${home}/snippets/tool-adapters"
  if [[ -d $adir ]]; then
    local af tool present active rel
    for af in $adir/*.zsh(N); do
      tool=${af:t:r}
      rel="snippets/tool-adapters/${tool}.zsh"
      present=$(_m1zsh_doctor_adapter_present "$tool")
      active='no'
      if (( ${+_M1ZSH_LOADED_SNIPPETS} )); then
        if (( ${_M1ZSH_LOADED_SNIPPETS[(Ie)$rel]} )); then
          active='yes'
        fi
      fi
      adapter_rows+=("${tool}|${present}|${active}")
      if [[ $present == yes && $active == no ]]; then
        _m1zsh_doctor_note warn adapter "${tool}: tool installed but adapter not activated" \
          "ensure modules/70-tools.zsh ran and M1ZSH_DISABLE_TOOL_ADAPTERS is unset"
      fi
    done
  fi

  # ---- 6. compinit status ----
  local zcompdump=${ZSH_COMPDUMP:-${ZDOTDIR:-${HOME:-.}}/.zcompdump}
  local zcd_state='missing' zcd_age='-'
  local -i zcd_age_days=-1
  if [[ -r $zcompdump ]]; then
    zcd_state='present'
    local mt now age
    mt=$(_m1zsh_doctor_mtime "$zcompdump")
    now=${EPOCHSECONDS:-$(date +%s)}
    if (( now > mt && mt > 0 )); then
      age=$(( now - mt ))
      zcd_age_days=$(( age / 86400 ))
      zcd_age="${zcd_age_days}d"
      if (( zcd_age_days > 30 )); then
        _m1zsh_doctor_note warn compinit "zcompdump is ${zcd_age_days} days old" \
          "rm $(_m1zsh_doctor_tildify $zcompdump) && exec zsh"
      fi
    fi
  else
    _m1zsh_doctor_note warn compinit "zcompdump missing at $(_m1zsh_doctor_tildify $zcompdump)"
  fi
  local insecure=''
  if (( ${+functions[compaudit]} )); then
    insecure=$(compaudit 2>/dev/null) || insecure=''
    if [[ -n ${insecure//[$'\n\t ']/} ]]; then
      _m1zsh_doctor_note error compaudit "insecure completion directories" \
        "compaudit | xargs chmod g-w,o-w"
    fi
  fi

  # ---- 7. fpath / path ----
  local -i fpath_missing=0 path_missing=0 path_dupes=0
  local d
  for d in $fpath; do
    [[ -d $d ]] || (( fpath_missing++ ))
  done
  for d in $path; do
    [[ -d $d ]] || (( path_missing++ ))
  done
  local -A _seen
  for d in $path; do
    if (( ${+_seen[$d]} )); then
      (( path_dupes++ ))
    else
      _seen[$d]=1
    fi
  done
  (( fpath_missing > 0 )) && _m1zsh_doctor_note warn fpath "${fpath_missing} fpath entries do not exist"
  (( path_missing > 0 )) && _m1zsh_doctor_note warn path "${path_missing} PATH entries do not exist"
  (( path_dupes > 0 ))   && _m1zsh_doctor_note warn path "${path_dupes} duplicate PATH entries" "typeset -gU path"

  # ---- 8. HISTFILE ----
  local histfile=${HISTFILE:-}
  local hist_readable='no'
  local -i hist_size=0
  if [[ -n $histfile ]]; then
    if [[ -r $histfile ]]; then
      hist_readable='yes'
      hist_size=$(_m1zsh_doctor_filesize "$histfile")
    else
      _m1zsh_doctor_note warn history "HISTFILE not readable: $(_m1zsh_doctor_tildify $histfile)"
    fi
  else
    _m1zsh_doctor_note warn history "HISTFILE unset"
  fi

  # ---- 9. brew ----
  local brew=${HOMEBREW_PREFIX:-}

  # ---- 10. personal overlay ----
  local personal_file=${M1ZSH_PERSONAL_FILE:-}
  local xdg=${XDG_CONFIG_HOME:-${HOME:-.}/.config}
  local personal_dir="$xdg/m1zsh/local"
  local -i personal_count=0
  if [[ -d $personal_dir ]]; then
    local -a _snips
    _snips=( $personal_dir/*.zsh(N) )
    personal_count=${#_snips}
  fi
  local personal_file_state='unset'
  if [[ -n $personal_file ]]; then
    if [[ -r $personal_file ]]; then
      personal_file_state='readable'
    else
      personal_file_state='set-but-unreadable'
      _m1zsh_doctor_note warn personal "M1ZSH_PERSONAL_FILE set but not readable"
    fi
  fi

  # ============================================================
  # OUTPUT
  # ============================================================

  if [[ $mode == json ]]; then
    print -rn -- '{'
    print -rn -- '"version":'; _m1zsh_doctor_json_str "$version"
    print -rn -- ',"home":';   _m1zsh_doctor_json_str "$(_m1zsh_doctor_tildify ${home:-})"
    print -rn -- ',"sha":';    _m1zsh_doctor_json_str "$sha"
    print -rn -- ',"zsh_version":'; _m1zsh_doctor_json_str "$zver"
    print -rn -- ',"zsh_path":';    _m1zsh_doctor_json_str "$(_m1zsh_doctor_tildify $zpath)"
    print -rn -- ",\"zi\":\"${zi_status}\""

    print -rn -- ',"modules":{'
    local first=1 entry name state
    for entry in $module_rows; do
      name=${entry%%=*}; state=${entry##*=}
      (( first )) || print -rn -- ','
      first=0
      print -rn -- "\"${name}\":\"${state}\""
    done
    print -rn -- '}'

    print -rn -- ',"adapters":['
    first=1
    local n rest p a
    for entry in $adapter_rows; do
      (( first )) || print -rn -- ','
      first=0
      n=${entry%%|*}; rest=${entry#*|}
      p=${rest%%|*}; a=${rest##*|}
      print -rn -- "{\"tool\":\"${n}\",\"present\":\"${p}\",\"activated\":\"${a}\"}"
    done
    print -rn -- ']'

    print -rn -- ',"compinit":{'
    print -rn -- '"zcompdump":'; _m1zsh_doctor_json_str "$(_m1zsh_doctor_tildify $zcompdump)"
    print -rn -- ",\"state\":\"${zcd_state}\",\"age_days\":${zcd_age_days}"
    print -rn -- ',"insecure":'; _m1zsh_doctor_json_str "${insecure//$'\n'/ }"
    print -rn -- '}'

    print -rn -- ",\"fpath\":{\"count\":${#fpath},\"missing\":${fpath_missing}}"
    print -rn -- ",\"path\":{\"count\":${#path},\"missing\":${path_missing},\"duplicates\":${path_dupes}}"

    print -rn -- ',"history":{'
    print -rn -- '"file":'; _m1zsh_doctor_json_str "$(_m1zsh_doctor_tildify ${histfile:-})"
    print -rn -- ",\"readable\":\"${hist_readable}\",\"size\":${hist_size}"
    print -rn -- '}'

    print -rn -- ',"brew":'; _m1zsh_doctor_json_str "$(_m1zsh_doctor_tildify ${brew:-})"

    print -rn -- ',"personal":{'
    print -rn -- '"file":'; _m1zsh_doctor_json_str "$(_m1zsh_doctor_tildify ${personal_file:-})"
    print -rn -- ",\"file_state\":\"${personal_file_state}\""
    print -rn -- ',"local_dir":'; _m1zsh_doctor_json_str "$(_m1zsh_doctor_tildify $personal_dir)"
    print -rn -- ",\"snippet_count\":${personal_count}"
    print -rn -- '}'

    print -rn -- ',"summary":{'
    print -rn -- "\"ok\":${oks},\"warn\":${warns},\"error\":${errs}"
    print -rn -- '},"findings":['
    first=1
    local f lvl msg rec rest2
    local cat_
    for f in $findings; do
      lvl=${f%%|*};  rest2=${f#*|}
      cat_=${rest2%%|*}; rest2=${rest2#*|}
      msg=${rest2%%|*}; rec=${rest2#*|}
      [[ $lvl == ok ]] && continue
      (( first )) || print -rn -- ','
      first=0
      print -rn -- "{\"level\":\"${lvl}\",\"category\":\"${cat_}\","
      print -rn -- '"message":'; _m1zsh_doctor_json_str "$msg"
      print -rn -- ',"recommendation":'; _m1zsh_doctor_json_str "$rec"
      print -rn -- '}'
    done
    print -- ']}'

    (( errs > 0 )) && return 1
    (( warns > 0 )) && return 2
    return 0
  fi

  if [[ $mode == quiet ]]; then
    print -r -- "m1zsh ${version} home=$(_m1zsh_doctor_tildify ${home:-?}) zi=${zi_status} ok=${oks} warn=${warns} err=${errs}"
    (( errs > 0 )) && return 1
    (( warns > 0 )) && return 2
    return 0
  fi

  # ---------- text mode ----------
  _m1zsh_doctor_sec() {
    print -r -- "${C_CYAN}=== $* ===${C_RESET}"
  }
  local _sec=_m1zsh_doctor_sec

  $_sec "m1zsh"
  print -r -- "  version : ${version}"
  print -r -- "  home    : $(_m1zsh_doctor_tildify ${home:-?})"
  [[ -n $sha ]] && print -r -- "  git sha : ${sha}"

  $_sec "shell"
  print -r -- "  ZSH_VERSION : ${zver}"
  print -r -- "  interpreter : $(_m1zsh_doctor_tildify $zpath)"

  $_sec "zi"
  print -r -- "  status : ${zi_status}"

  $_sec "modules"
  local entry name state badge
  for entry in $module_rows; do
    name=${entry%%=*}; state=${entry##*=}
    if [[ $state == hit ]]; then
      badge="${C_GRN}[hit]${C_RESET} "
    else
      badge="${C_YEL}[miss]${C_RESET}"
    fi
    print -r -- "  ${badge} ${name}"
  done

  $_sec "tool adapters"
  printf '  %-10s %-9s %-9s\n' tool present activated
  printf '  %-10s %-9s %-9s\n' ---- ------- ---------
  local n rest p a pm am
  for entry in $adapter_rows; do
    n=${entry%%|*}; rest=${entry#*|}
    p=${rest%%|*}; a=${rest##*|}
    if (( use_color )); then
      [[ $p == yes ]] && pm="${C_GRN}yes${C_RESET}" || pm="${C_DIM}no ${C_RESET}"
      [[ $a == yes ]] && am="${C_GRN}yes${C_RESET}" || am="${C_DIM}no ${C_RESET}"
      # printf can't measure ANSI width; pad raw word and colourize separately.
      printf '  %-10s %s        %s\n' "$n" "$pm" "$am"
    else
      printf '  %-10s %-9s %-9s\n' "$n" "$p" "$a"
    fi
  done

  $_sec "completion"
  print -r -- "  zcompdump : $(_m1zsh_doctor_tildify $zcompdump) [${zcd_state}, age=${zcd_age}]"
  if [[ -n ${insecure//[$'\n\t ']/} ]]; then
    print -r -- "  compaudit : ${C_RED}insecure${C_RESET}"
    local line
    for line in ${(f)insecure}; do
      print -r -- "              - $(_m1zsh_doctor_tildify $line)"
    done
  else
    print -r -- "  compaudit : ${C_GRN}ok${C_RESET}"
  fi

  $_sec "fpath / path"
  print -r -- "  fpath : ${#fpath} entries (missing: ${fpath_missing})"
  print -r -- "  path  : ${#path} entries (missing: ${path_missing}, dupes: ${path_dupes})"

  $_sec "history"
  print -r -- "  HISTFILE : $(_m1zsh_doctor_tildify ${histfile:-not set})"
  print -r -- "  readable : ${hist_readable}"
  print -r -- "  size     : ${hist_size} bytes"

  $_sec "brew"
  print -r -- "  HOMEBREW_PREFIX : $(_m1zsh_doctor_tildify ${brew:-not set})"

  $_sec "personal overlay"
  print -r -- "  M1ZSH_PERSONAL_FILE : $(_m1zsh_doctor_tildify ${personal_file:-not set}) [${personal_file_state}]"
  print -r -- "  local dir           : $(_m1zsh_doctor_tildify $personal_dir)"
  print -r -- "  snippet count       : ${personal_count}"

  $_sec "summary"
  print -r -- "  ok=${oks} warn=${warns} error=${errs}"
  if (( errs == 0 && warns == 0 )); then
    print -r -- "  ${C_GRN}all checks passed${C_RESET}"
  else
    local f lvl msg rec rest2 color label
    local cat_
    for f in $findings; do
      lvl=${f%%|*};  rest2=${f#*|}
      cat_=${rest2%%|*}; rest2=${rest2#*|}
      msg=${rest2%%|*}; rec=${rest2#*|}
      case $lvl in
        error) color=$C_RED;  label='ERROR' ;;
        warn)  color=$C_YEL;  label='WARN ' ;;
        ok)    continue ;;
      esac
      print -r -- "  ${color}${label}${C_RESET} [${cat_}] ${msg}"
      [[ -n $rec ]] && print -r -- "          -> ${rec}"
    done
  fi

  unfunction _m1zsh_doctor_sec 2>/dev/null

  (( errs > 0 )) && return 1
  (( warns > 0 )) && return 2
  return 0
}
