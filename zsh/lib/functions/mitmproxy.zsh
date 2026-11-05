# mitmproxy / mitmweb を共通の設定で起動する
#   使い方: mitmproxy [port] [mitmproxy のオプション...]
#           mitmweb   [port] [mitmweb のオプション...]
#   - 先頭の引数が数字ならポートとして使う（省略時は 8080）。残りの引数はそのまま渡す
#   - 上流 TLS の検証に使う CA は MITMPROXY_UPSTREAM_CA で渡す（未設定ならデフォルトの CA を使う）
#   - 通信ログは ~/mitm-logs/<ツール名>-YYYYMMDD-<ポート>.mitm に追記する（1日・ツール・ポートごとに1ファイル）
#     ~/.mitmproxy/config.yaml の save_stream_file より優先される
#   - mitmweb の Web UI のポートは「プロキシのポート + 1000」（8080 なら 9080）。複数起動してもぶつからない
#   - mitmweb の Web UI のパスワードは MITMWEB_PASSWORD で渡す（未設定なら起動時に表示されるトークンを使う）
function _mitm_run() {
  local tool=$1; shift
  local port=8080
  if [[ $1 == <-> ]]; then port=$1; shift; fi
  local -a opts
  [[ -n "${MITMPROXY_UPSTREAM_CA:-}" ]] && opts+=(--set ssl_verify_upstream_trusted_ca="$MITMPROXY_UPSTREAM_CA")
  opts+=(--set save_stream_file="+${HOME}/mitm-logs/${tool}-%Y%m%d-${port}.mitm")
  # mitmweb の Web UI はプロキシのポート + 1000（--web-port / web_port を指定した場合はそちらを優先）
  if [[ $tool == mitmweb && "$*" != *--web-port* && "$*" != *web_port=* ]]; then
    opts+=(--web-port $(( port + 1000 )))
  fi
  # mitmweb の Web UI のパスワードは MITMWEB_PASSWORD で渡す（未設定なら起動時に表示されるトークンを使う）
  if [[ $tool == mitmweb && -n "${MITMWEB_PASSWORD:-}" ]]; then
    opts+=(--set web_password="$MITMWEB_PASSWORD")
  fi
  command "$tool" "${opts[@]}" -p "$port" "$@"
}

function mitmproxy() { _mitm_run mitmproxy "$@"; }
function mitmweb()   { _mitm_run mitmweb "$@"; }
