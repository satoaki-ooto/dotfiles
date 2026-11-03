# GH_COMPANY=0 (または MISE_GITHUB_TOKEN/GITHUB_TOKEN 設定済み) なら ghtkn を経由せず mise を実行する
function mise() {
  if [[ "${GH_COMPANY:-1}" == "0" || -n "${MISE_GITHUB_TOKEN:-}" || -n "${GITHUB_TOKEN:-}" ]]; then
    $HOME/.local/bin/mise "$@"
    return
  fi

  ghtkn_agent_ensure || return
  local token
  token="$(ghtkn_token "$GHTKN_APP")" || return
  MISE_GITHUB_TOKEN="$token" $HOME/.local/bin/mise "$@"
}
