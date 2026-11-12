# set SSH_AUTH_SOCK
_configure_ssh_agent() {
    # SSH ログイン先で agent 転送されている場合だけは既存のソケットを尊重する
    # それ以外（macOS launchd / gcr-agent / herdr など OS やツールが勝手に設定したもの）は
    # 除外リストで個別対応せず、常に Keeper/Bitwarden を優先する。
    # どの候補も存在しなければ既存の SSH_AUTH_SOCK をそのまま残す。
    if [ -n "${SSH_CONNECTION:-}" ] && [ -S "${SSH_AUTH_SOCK:-}" ]; then
        return
    fi

    local _os _sock
    local -a _socks
    _os="$(uname -s)"
    case "$_os" in
        Darwin)
            _socks+=("$HOME/.bitwarden-ssh-agent.sock")
            # Keeper は App Store 版 (com.callpod.keepermac.lite) で、App Sandbox のため
            # ~/Library/Containers/<bundle id>/Data/tmp/ 配下にソケットを作る。
            # 以前は ~/.keeper/*.ssh_agent を見ていたが、そこには応答しないソケットファイルしかなく、
            # Keeper が動いていても launchd のソケットに落ちていたため候補から外した（2026-11）。
            _socks+=("$HOME/Library/Containers/com.callpod.keepermac.lite/Data/tmp/keeper-ssh-agent.sock")
            ;;
        Linux)
            local _id
            _id="$(
                ID=
                if [ -r /etc/os-release ]; then
                    . /etc/os-release
                elif [ -r /usr/lib/os-release ]; then
                    . /usr/lib/os-release
                fi
                printf '%s' "$ID"
            )"
            # Ubuntu は Snap 優先、それ以外の Linux は Flatpak 優先とする
            if [ "$_id" = "ubuntu" ]; then
                _socks+=("$HOME/snap/keepersecurity/current/.config/Keeper Password Manager/keeper-ssh-agent.sock")
                _socks+=("$HOME/snap/bitwarden/current/.bitwarden-ssh-agent.sock")
                _socks+=("$HOME/.var/app/com.bitwarden.desktop/data/.bitwarden-ssh-agent.sock")
            else
                _socks+=("$HOME/.var/app/com.bitwarden.desktop/data/.bitwarden-ssh-agent.sock")
                _socks+=("$HOME/snap/keepersecurity/current/.config/Keeper Password Manager/keeper-ssh-agent.sock")
                _socks+=("$HOME/snap/bitwarden/current/.bitwarden-ssh-agent.sock")
            fi
            ;;
    esac

    # ソケットファイルはアプリ終了後も残ることがあるため、実際に agent が応答するかも確認する
    # (ssh-add -l の終了コード: 0=鍵あり / 1=鍵なしだが agent は生きている / 2=接続不可)
    for _sock in "${_socks[@]}"; do
        if [ -S "$_sock" ]; then
            SSH_AUTH_SOCK="$_sock" ssh-add -l >/dev/null 2>&1
            [ $? -le 1 ] || continue
            export SSH_AUTH_SOCK="$_sock"
            return
        fi
    done
}
_configure_ssh_agent
unset -f _configure_ssh_agent

# EDITOR & VISUAL editor
export EDITOR=$(which hx)
export VISUAL=$(which hx)

export SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt"
