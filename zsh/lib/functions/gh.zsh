# GH_COMPANY=0 (または GH_TOKEN/GITHUB_TOKEN 設定済み) なら ghtkn を経由せず gh を実行する
function gh() {
  if [[ "${GH_COMPANY:-1}" == "0" || -n "${GH_TOKEN:-}" || -n "${GITHUB_TOKEN:-}" ]]; then
    # command で関数を回避。mise activate の shim 経由で実行される
    command gh "$@"
    return
  fi

  ghtkn_agent_ensure || return
  $HOME/.local/bin/gh "$@"

  #local token
  #token="$(ghtkn_token "$GHTKN_APP")" || return
  #GH_TOKEN="$token" command gh "$@"
}
