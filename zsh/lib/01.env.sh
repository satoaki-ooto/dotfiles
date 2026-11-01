# set SSH_AUTH_SOCK
_configure_ssh_agent() {
    # SSH 転送や macOS launchd など、既に有効なソケットを指している場合はそのままにする
    [ -S "${SSH_AUTH_SOCK:-}" ] && return

    local _os _sock
    _os="$(uname -s)"
    case "$_os" in
        Darwin)
            set -- "$HOME/.bitwarden-ssh-agent.sock"
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
                set -- "$HOME/snap/keepersecurity/current/.config/Keeper Password Manager/keeper-ssh-agent.sock" \
                    "$HOME/snap/bitwarden/current/.bitwarden-ssh-agent.sock" \
                    "$HOME/.var/app/com.bitwarden.desktop/data/.bitwarden-ssh-agent.sock"
            else
                set -- "$HOME/.var/app/com.bitwarden.desktop/data/.bitwarden-ssh-agent.sock" \
                    "$HOME/snap/keepersecurity/current/.config/Keeper Password Manager/keeper-ssh-agent.sock" \
                    "$HOME/snap/bitwarden/current/.bitwarden-ssh-agent.sock"
            fi
            ;;
    esac

    for _sock in "$@"; do
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
