# リポジトリの構成

| ファイル | 役割 |
|---|---|
| `config.toml` | 全端末共通（tools / packages / prezto clone / dotfiles 宣言） |
| `config.personal.toml` | 自宅PC向け（`env = ["personal"]` で読み込まれる） |
| `config.work.toml` | 会社PC向け（`env = ["work"]` で読み込まれる） |
| `miserc.local.toml` | 端末ごとの役割選択（gitignored、同期されない） |
| `zsh/` | zsh の runcom と断片。詳細は [zsh.md](zsh.md) |
| `agents/` | コーディングエージェントの設定。詳細は [agents.md](agents.md) |

- `zsh/zshrc` / `zsh/zpreztorc` / `zsh/zshenv` は `~/.zshrc` / `~/.zpreztorc` / `~/.zshenv` の実体
- `zsh/lib/` は `~/.zsh` の実体。全端末共通の断片
- `zsh/personal/` / `zsh/work/` は役割別の断片。`~/.zsh.personal` / `~/.zsh.work` として deploy
- `agents/shared/` は全エージェント共通の指示（`AGENTS.md` / `rules/`）
- `agents/<agent>/` はエージェント固有の設定。対応する設定ディレクトリへ deploy
