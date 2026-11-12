# ghtkn (agent backend) からトークンを取り出すための共通関数
#
# 想定する壊れ方と対処:
#   - 再起動後: agent が居ない（socket ファイルだけ残る）→ start して unlock
#   - 起動済みだがロック中（unlock の中断・ghtkn agent lock 等）→ unlock
#   - トークン期限切れ（refresh 無効時は約 8h）→ ghtkn auth（device flow）
# ghtkn v0.4 以降は get / exec が device flow を始めないため、ここで先回りして直す。
# unlock (passphrase 入力) と auth (device flow) は制御端末 /dev/tty で自動実行する。
# stdin/stdout/stderr がパイプ・リダイレクト・$(...) でも、端末さえあれば動く。
# 制御端末が無い (cron・launchd・エディタ/エージェントの子プロセス等) ときだけ失敗する。

# トークン取得前に要求する残り有効期限
: ${GHTKN_MIN_EXPIRATION:=5m}

# 制御端末を開けるか（passphrase 入力や device flow ができるか）
function __ghtkn_has_tty() {
  { : </dev/tty } 2>/dev/null
}

# agent の状態を "running locked refresh" の形で出力する（例: "true false true"）
# ghtkn info はトークンを含まないので安全に状態確認に使える
function __ghtkn_agent_state() {
  # jq の // は false も「値なし」扱いするので、キーの有無で既定値を決める
  ghtkn info 2>/dev/null | jq -r '
    .agent // {}
    | [ .running == true,
        (if has("locked") then .locked else true end),
        .refresh_token.enabled == true ]
    | map(tostring) | join(" ")' 2>/dev/null || print "false true false"
}

function ghtkn_agent_unlock() {
  if ! __ghtkn_has_tty; then
    print -u2 "ghtkn agent is locked and no terminal is available to enter the passphrase; ask the user to run in their terminal: ghtkn agent unlock --enable-refresh"
    return 1
  fi
  print -r "ghtkn agent is locked; unlocking" >/dev/tty
  ghtkn agent unlock --enable-refresh --refresh-token-ttl 2d </dev/tty >/dev/tty 2>&1
}

# agent を「起動済み・アンロック済み」にする
function ghtkn_agent_ensure() {
  local running locked refresh
  read -r running locked refresh <<<"$(__ghtkn_agent_state)"

  if [[ "$running" != true ]]; then
    # 古い socket ファイルが残っていても ghtkn agent start が置き換える
    ghtkn agent start </dev/null >/dev/null 2>&1 &!
    local i
    for i in {1..50}; do
      read -r running locked refresh <<<"$(__ghtkn_agent_state)"
      [[ "$running" == true ]] && break
      sleep 0.1
    done
    if [[ "$running" != true ]]; then
      print -u2 "failed to start ghtkn agent"
      return 1
    fi
  fi

  [[ "$locked" == true ]] || return 0
  ghtkn_agent_unlock || return 1

  read -r running locked refresh <<<"$(__ghtkn_agent_state)"
  [[ "$locked" != true ]]
}

# app のトークンが GHTKN_MIN_EXPIRATION 以上有効か確認し、無ければその場で ghtkn auth する
# 確認は ghtkn exec で行い、トークンをシェルに取り出さない（exit 111 = 取得不可）
function ghtkn_token_ensure() {
  local app=$1
  ghtkn exec -e "__GHTKN_CHECK:$app" -m "$GHTKN_MIN_EXPIRATION" -- true 2>/dev/null && return 0

  if ! __ghtkn_has_tty; then
    print -u2 "$app token is expired or missing and no terminal is available for the device flow; ask the user to run in their terminal: ghtkn auth $app"
    return 1
  fi

  print -r "$app token is expired or missing; starting ghtkn auth" >/dev/tty
  local running locked refresh
  read -r running locked refresh <<<"$(__ghtkn_agent_state)"
  if [[ "$refresh" != true ]]; then
    print -r "hint: refresh tokens are disabled; to skip this next time run: ghtkn agent lock && ghtkn agent unlock --enable-refresh" >/dev/tty
  fi
  ghtkn auth "$app" </dev/tty >/dev/tty 2>&1 || return 1
  ghtkn exec -e "__GHTKN_CHECK:$app" -m "$GHTKN_MIN_EXPIRATION" -- true 2>/dev/null
}

# 使う App 名を出力する。アプリ名はリポジトリに載せないため GHTKN_APP（例: <org>/write）で渡す
# GHTKN_APP は config.local.toml の [env] にあり mise activate (対話シェル) で入るので、
# coding agent の非対話シェル等で未設定なら mise env から補う
function ghtkn_app() {
  if [[ -n "${GHTKN_APP:-}" ]]; then
    print -r -- "$GHTKN_APP"
    return
  fi
  local app
  app="$(command mise env --json 2>/dev/null | jq -r '.GHTKN_APP // empty' 2>/dev/null)"
  [[ -n "$app" ]] && print -r -- "$app"
}

# agent の起動・unlock・期限切れ時の再認証までをまとめた入口
# 引数省略時は ghtkn_app の App を使う
function ghtkn_ready() {
  local app=${1:-$(ghtkn_app)}
  if [[ -z "$app" ]]; then
    print -u2 "ghtkn app is not set; set GHTKN_APP (e.g. [env] in config.local.toml)"
    return 1
  fi
  ghtkn_agent_ensure || return
  ghtkn_token_ensure "$app"
}

# 例: token="$(ghtkn_token "$GHTKN_APP")" || return
function ghtkn_token() {
  local app=${1:-$(ghtkn_app)}
  ghtkn_ready "$app" || return
  ghtkn get -m "$GHTKN_MIN_EXPIRATION" "$app"
}
