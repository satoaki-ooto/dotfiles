# GH_COMPANY=0 (または MISE_GITHUB_TOKEN/GITHUB_TOKEN 設定済み) なら ghtkn を経由せず mise を実行する
#
# このファイルはローダの *.zsh 段階と、00.eval.sh の mise activate 後に読まれる。
# mise activate は既存の mise() を unset して自前の関数を定義し直すため、
# activate 後に読まれたときは activate の関数を退避して委譲先にする。
# （sh / shell / deactivate は activate の関数が eval する特別扱いを持つため、
# ラッパーから素のバイナリを直接呼ぶとその挙動が失われる）
if (( $+functions[mise] )) && [[ "${functions[mise]}" != *ghtkn* ]]; then
  functions[__mise_activate_original]=$functions[mise]
fi

function mise() {
  if [[ "${GH_COMPANY:-1}" == "0" || -n "${MISE_GITHUB_TOKEN:-}" || -n "${GITHUB_TOKEN:-}" ]]; then
    __mise_dispatch "$@"
    return
  fi

  local token
  token="$(ghtkn_token "$GHTKN_APP")" || return
  local -x MISE_GITHUB_TOKEN="$token"
  __mise_dispatch "$@"
}

# activate 由来の関数が退避されていればそちらへ委譲し、無ければ素のバイナリを実行する
function __mise_dispatch() {
  if (( $+functions[__mise_activate_original] )); then
    __mise_activate_original "$@"
  else
    "$HOME/.local/bin/mise" "$@"
  fi
}
