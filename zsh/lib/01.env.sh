# set SSH_AUTH_SOCK
_configure_ssh_agent() {
    # SSH 転送や macOS launchd など、既に有効なソケットを指している場合はそのままにする
    # ただし gcr-agent (GNOME) と herdr の agent ソケットは Keeper/Bitwarden を優先したいので対象外
    case "${SSH_AUTH_SOCK:-}" in
        ""|*/gcr/ssh|*/herdr.sock.agent) ;;
        *) [ -S "$SSH_AUTH_SOCK" ] && return ;;
    esac

    local _os _sock
    local -a _socks
    _os="$(uname -s)"
    case "$_os" in
        Darwin)
            _socks+=("$HOME/.bitwarden-ssh-agent.sock")
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

    for _sock in "${_socks[@]}"; do
        if [ -S "$_sock" ]; then
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
