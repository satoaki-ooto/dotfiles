# GH_COMPANY=0 (または GH_TOKEN/GITHUB_TOKEN 設定済み) なら ghtkn を経由せず gh を実行する
#
# 対話シェルでは zshrc のローダが読む。coding agent 等の非対話 zsh (zsh -c) でも
# PATH 上の素の gh (mise / Homebrew) より優先されるよう、zshenv からも読む。
function gh() {
  if [[ "${GH_COMPANY:-1}" == "0" || -n "${GH_TOKEN:-}" || -n "${GITHUB_TOKEN:-}" ]]; then
    # command で関数を回避。mise activate の shim 経由で実行される
    command gh "$@"
    return
  fi

  # gh.zsh だけが読まれた場合（古い shell snapshot 等）でも動くよう、必要なら ghtkn.zsh を読む
  if (( ! $+functions[ghtkn_ready] )); then
    source "$HOME/.zsh/functions/ghtkn.zsh" || return
  fi

  # agent の起動・unlock・期限切れ時の ghtkn auth を先に済ませてから、
  # ghtkn exec でトークンを渡すラッパー (~/.local/bin/gh) を呼ぶ
  local app
  app="$(ghtkn_app)"
  ghtkn_ready "$app" || return
  GHTKN_APP="$app" $HOME/.local/bin/gh "$@"
}
