function ghtkn_agent_is_running() {
  local agent_status_output
  agent_status_output="$(ghtkn agent status 2>&1)"
  [[ "$agent_status_output" == *"ghtkn agent is running"* ]]
}

# ghtkn_token は $(...) 内で呼ばれるので、unlock の出力がトークンに混ざらないよう stderr へ逃がす
function ghtkn_agent_unlock() {
  ghtkn agent unlock --enable-refresh --refresh-token-ttl 2d >&2
}

function ghtkn_agent_ensure() {
  ghtkn_agent_is_running && return 0

  ghtkn agent start </dev/null >/dev/null 2>&1 &!

  local i
  for i in {1..50}; do
    if ghtkn_agent_is_running; then
      ghtkn_agent_unlock
      return 0
    fi
    sleep 0.1
  done

  print -u2 "failed to start ghtkn agent"
  return 1
}

# ghtkn から秘密情報を取得する。ロックされていれば unlock して 1 回だけ再試行する
function ghtkn_get_token() {
  local secret=$1
  ghtkn get "$secret" 2>/dev/null && return 0

  ghtkn_agent_unlock
  ghtkn get "$secret" 2>/dev/null && return 0

  # Device Flow は対話が必要なので、端末から呼ばれたときだけ自動で ghtkn auth する
  [[ -t 0 && -t 2 ]] || return 1
  ghtkn auth "$secret" >&2 || return 1
  ghtkn get "$secret"
}

# agent の起動からトークン取得までをまとめた入口。各アプリのラッパーからはこれを呼ぶ
# アプリ名はリポジトリに載せないため GHTKN_APP（例: <org>/write）で渡す
# 例: token="$(ghtkn_token "$GHTKN_APP")" || return
function ghtkn_token() {
  local app=$1
  if [[ -z "$app" ]]; then
    print -u2 "ghtkn app is not set; export GHTKN_APP (e.g. in zsh/work/*.local.zsh)"
    return 1
  fi
  ghtkn_agent_ensure || return

  if ! ghtkn_get_token "$app"; then
    print -u2 "$app token is unavailable; run: ghtkn auth $app"
    return 1
  fi
}
