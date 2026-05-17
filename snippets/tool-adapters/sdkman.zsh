# SDKMAN integration.

: "${SDKMAN_DIR:=$HOME/.sdkman}"
[[ -r "$SDKMAN_DIR/bin/sdkman-init.sh" ]] && source "$SDKMAN_DIR/bin/sdkman-init.sh"
