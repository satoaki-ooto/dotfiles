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
# ghtkn info / agent status はトークンを含まないので安全に状態確認に使える。
# 状態が取れなかったときは何も出力せず失敗する（呼び出し側は fail closed で扱う）
function __ghtkn_agent_state() {
  setopt localoptions pipefail extendedglob
  local state
  if (( $+commands[jq] )); then
    # jq の // は false も「値なし」扱いするので、キーの有無で既定値を決める
    state="$(ghtkn info 2>/dev/null | jq -er '
      .agent // {}
      | [ .running == true,
          (if has("locked") then .locked else true end),
          .refresh_token.enabled == true ]
      | map(tostring) | join(" ")' 2>/dev/null)" || return 1
  else
    # jq が無い環境では ghtkn agent status のログ文言で判定する
    local out refresh=false
    out="$(ghtkn agent status 2>&1)" || return 1
    out="${out//$'\e'\[[0-9;]#m/}"
    [[ "$out" == *"refresh_token_enabled=true"* ]] && refresh=true
    case "$out" in
      (*"agent is not running"*) state="false true false" ;;
      (*"running and unlocked"*) state="true false $refresh" ;;
      (*"running but locked"*)   state="true true false" ;;
      (*) return 1 ;;
    esac
  fi
  [[ "$state" == (true|false)" "(true|false)" "(true|false) ]] || return 1
  print -r -- "$state"
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
  local state running locked refresh
  if ! state="$(__ghtkn_agent_state)"; then
    print -u2 "failed to query the ghtkn agent state (ghtkn info)"
    return 1
  fi
  read -r running locked refresh <<<"$state"

  if [[ "$running" != true ]]; then
    # 古い socket ファイルが残っていても ghtkn agent start が置き換える
    ghtkn agent start </dev/null >/dev/null 2>&1 &!
    local i
    for i in {1..50}; do
      state="$(__ghtkn_agent_state)" && read -r running locked refresh <<<"$state"
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

  # 状態が取れない場合も含め、アンロックを確認できたときだけ成功にする
  state="$(__ghtkn_agent_state)" || return 1
  read -r running locked refresh <<<"$state"
  [[ "$locked" == false ]]
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
  local state running locked refresh
  state="$(__ghtkn_agent_state)" && read -r running locked refresh <<<"$state"
  if [[ "$refresh" == false ]]; then
    print -r "hint: refresh tokens are disabled; to skip this next time run: ghtkn agent lock && ghtkn agent unlock --enable-refresh" >/dev/tty
  fi
  ghtkn auth "$app" </dev/tty >/dev/tty 2>&1 || return 1
  ghtkn exec -e "__GHTKN_CHECK:$app" -m "$GHTKN_MIN_EXPIRATION" -- true 2>/dev/null
}

# 使う App 名を出力する。アプリ名はリポジトリに載せないため GHTKN_APP（例: <org>/write）で渡す
# GHTKN_APP は config.local.toml の [env] にあり mise activate (対話シェル) で入るので、
# coding agent の非対話シェル等で未設定なら mise env から補う。
# jq に依存しないよう、mise env の出力をサブシェルで評価して取り出す
function ghtkn_app() {
  if [[ -n "${GHTKN_APP:-}" ]]; then
    print -r -- "$GHTKN_APP"
    return
  fi
  local app env_script
  env_script="$(command mise env -s zsh 2>/dev/null)" || return 1
  app="$(eval "$env_script" >/dev/null 2>&1; print -r -- "${GHTKN_APP:-}")"
  [[ -n "$app" ]] || return 1
  print -r -- "$app"
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
