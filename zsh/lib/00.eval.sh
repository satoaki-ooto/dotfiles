# mise
if [ -f "$HOME/.local/bin/mise" ] && [ -x "$HOME/.local/bin/mise" ]; then
  if [ -n "${ZSH_VERSION-}" ]; then
    eval "$("$HOME/.local/bin/mise" activate zsh)"
    # mise activate は既存の mise() を unset して自前の関数を定義し直す。
    # ローダは *.zsh → *.sh の順で読むため ghtkn トークンを渡すラッパー
    # （functions/mise.zsh）だけでは activate に負ける。activate の後で読み直す
    if [ -r "$HOME/.zsh/functions/mise.zsh" ]; then
      source "$HOME/.zsh/functions/mise.zsh"
    fi
  elif [ -n "${BASH_VERSION-}" ]; then
    eval "$("$HOME/.local/bin/mise" activate bash)"
  fi
fi

# Homebrew
if [ -x /opt/homebrew/bin/brew ] && [ -f /opt/homebrew/bin/brew ]; then
  if [ -n "${ZSH_VERSION-}" ]; then
    eval "$(/opt/homebrew/bin/brew shellenv zsh)"
  elif [ -n "${BASH_VERSION-}" ]; then
    eval "$(/opt/homebrew/bin/brew shellenv bash)"
  fi
elif [ -x /home/linuxbrew/.linuxbrew/bin/brew ]; then
  if [ -n "${ZSH_VERSION-}" ]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv zsh)"
  elif [ -n "${BASH_VERSION-}" ]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv bash)"
  fi
fi

# Path Check
if command -v wt >/dev/null 2>&1; then eval "$(command wt config shell init zsh)"; fi
if command -v phantom >/dev/null 2>&1; then eval "$(phantom completion zsh)"; fi

# ~/.zshrc
_load_global_secrets() {
  local f="$HOME/.config/secrets/global.yaml"
  [[ -r $f ]] || return
  command -v sops jq >/dev/null || return
  eval "$(sops decrypt --output-type json "$f" \
    | jq -r 'to_entries[] | "export \(.key)=\(.value | @sh)"')"
}

_load_global_secrets
