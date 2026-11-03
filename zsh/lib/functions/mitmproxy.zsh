# 上流 TLS の検証に使う CA は MITMPROXY_UPSTREAM_CA で渡す（未設定ならデフォルトの CA を使う）
function mitmproxy() {
  local port=${1:-8080}
  local -a opts
  [[ -n "${MITMPROXY_UPSTREAM_CA:-}" ]] && opts+=(--set ssl_verify_upstream_trusted_ca="$MITMPROXY_UPSTREAM_CA")
  command mitmproxy "${opts[@]}" -p "$port"
}
