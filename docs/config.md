# リポジトリの構成

| ファイル | 役割 |
|---|---|
| `config.toml` | 全端末共通（tools / packages / prezto clone / dotfiles 宣言） |
| `config.personal.toml` | 自宅PC向け（`env = ["personal"]` で読み込まれる） |
| `config.work.toml` | 会社PC向け（`env = ["work"]` で読み込まれる） |
| `config.macos.toml` / `config.linux.toml` | OS 別の差分。`miserc.toml` の `auto_env` で OS を判定して自動読み込み（役割選択と独立）。pig は OS で設定 root が違うため target をここで変える |
| `miserc.toml` | mise の起動設定（`auto_env`）。config の読み込み制御のため config.toml 側には書けない |
| `packages/` | 1 パッケージ 1 ファイルのツール定義。役割別 config の `[dotfiles]` で `conf.d/` に symlink したものだけが読まれる |
| `conf.d/` | 選んだパッケージの symlink 置き場（gitignored。global config として読まれる） |
| `miserc.local.toml` | 端末ごとの役割選択（gitignored、同期されない） |
| `zsh/` | zsh の runcom と断片。詳細は [zsh.md](zsh.md) |
| `agents/` | コーディングエージェントの設定。詳細は [agents.md](agents.md) |

- `zsh/zshrc` / `zsh/zpreztorc` / `zsh/zshenv` は `~/.zshrc` / `~/.zpreztorc` / `~/.zshenv` の実体
- `zsh/lib/` は `~/.zsh` の実体。全端末共通の断片
- `zsh/personal/` / `zsh/work/` は役割別の断片。`~/.zsh.personal` / `~/.zsh.work` として deploy
- `agents/shared/` は全エージェント共通の指示（`AGENTS.md` / `rules/`）
- `agents/<agent>/` はエージェント固有の設定。対応する設定ディレクトリへ deploy

## パッケージの追加・削除

`packages/<name>.toml` は `include` ではなく、`config.personal.toml` / `config.work.toml` の
`[dotfiles]` で `~/.config/mise/conf.d/<name>.toml` に symlink して有効にする。
`conf.d/` は global config として読まれるため、paranoid の `config` カテゴリを有効にしても
承認なしで読める（local `include` は `config` カテゴリで拒否され、config ファイル全体が読めなくなる）。

- 追加: `packages/<name>.toml` を作り、使う役割の config に
  `"~/.config/mise/conf.d/<name>.toml" = { source = "packages/<name>.toml", mode = "symlink" }` を足す。
  もう一方の役割で使わないなら、そちらに `{ mode = "absent" }` を足す
- 外す: エントリを `{ mode = "absent" }` に書き換える。エントリを消すだけだと配備済みの
  symlink が `conf.d/` に残り、読まれ続ける
- バージョン更新: `version` を書き換える。旧バージョンをコメントアウトで残さない
  （履歴・差分は git が持つ）。反映は `mise install`
- 反映: `mise dot apply` で `conf.d/` の symlink を作り直し、追加したパッケージは続けて
  `mise install` でインストールする（`mise bootstrap` なら両方を行う）。
  `mise dot apply` だけではツールはインストールされず、config を書き換えただけでは symlink も変わらない
- 新端末: `conf.d/` は bootstrap の dotfiles 手順で作られる。同じ実行の tools 手順がそれを
  読むかは未確認のため、adopt 後に `mise ls --current` で役割分のツールを確認し、
  足りなければもう一度 `mise bootstrap` する（README の手順 1 を参照。bootstrap は冪等）
