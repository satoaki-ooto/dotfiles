# dotfiles

[mise bootstrap](https://mise.jdx.dev/bootstrap.html) で仕事 / 自宅の端末を同じ構成にするためのリポジトリ。
`~/.config/mise` がこのリポジトリへの symlink になっており、mise のグローバル設定と zsh の runcom をまとめて管理する。

## 新しい端末のセットアップ

```sh
# mise 導入 & GitHub への SSH 認証を通しておく
curl https://mise.run | sh
ssh -T git@github.com

# このリポジトリを ~/.config/mise として取り込み、bootstrap を実行
mise bootstrap --adopt satoaki-ooto/dotfiles
```

既存の `~/.zshrc` などが食い違うと adopt は何も適用せずに止まる（上書きしない）。
確認して取り込む:

```sh
mise dot status
mise dot pull --take-remote-all   # 置き換え前の版は保存されるので mise dot undo で戻せる
mise bootstrap
```

## 端末の役割を選ぶ（personal / work）

共通設定は `config.toml`。端末固有の差分はモジュールとして分かれており、
各端末の `miserc.local.toml` で選択する（**gitignored**: 端末ごとに1回作る）:

```sh
# 自宅PC
printf 'env = ["personal"]\n' > ~/.config/mise/miserc.local.toml

# 会社PC
printf 'env = ["work"]\n' > ~/.config/mise/miserc.local.toml

# 確認して反映
mise config                    # 読み込まれたファイル一覧
mise bootstrap --dry-run
mise bootstrap
```

- その場限りで試す: `mise -E work bootstrap --dry-run`
- モジュールが作ったものを除去: `mise bootstrap unapply work`

## 構成

| ファイル | 役割 |
|---|---|
| `config.toml` | 全端末共通（tools / packages / prezto clone / dotfiles 宣言） |
| `config.personal.toml` | 自宅PC向け（`env = ["personal"]` で読み込まれる） |
| `config.work.toml` | 会社PC向け（`env = ["work"]` で読み込まれる） |
| `miserc.local.toml` | 端末ごとの役割選択（gitignored、同期されない） |
| `zsh/zshrc` | `~/.zshrc` の実体（prezto の init 読み込み + ローダ） |
| `zsh/lib/` | `~/.zsh` の実体。番号順に再帰読み込みされる断片 |

## zsh

- `~/.zshrc` → `zsh/zshrc`、`~/.zsh` → `zsh/lib` への symlink。編集はどちら側からでも同じ
- [prezto](https://github.com/sorin-ionescu/prezto) は `~/.zprezto` に `[bootstrap.repos]` が clone する（submodules 込み）。更新は `mise bootstrap repos update`
- `zsh/lib/` 内は `**/*.zsh` → `**/*.sh` の順で再帰 source。端末固有の断片は
  `*.local.sh` / `*.local.zsh` に書く（gitignored。`zz.local.sh` とすれば最後に読まれる）

## 日々の運用

- 編集はこのリポジトリ内で → `git commit`（SSH 署名は `commit.gpgsign` + `gpg.format=ssh` で自動）→ `git push`
- もう1台は `git pull`（symlink 先が更新される）。tools / packages の変更が入ったら `mise bootstrap`
- 設定の履歴・差分: `mise dot history` / `mise dot diff`

## 秘密情報

- sops + age で暗号化。実ファイル（`~/.config/secrets/*.yaml`、age 鍵）は**このリポジトリに含めない**
- 復号鍵は端末ごとに用意し、`SOPS_AGE_KEY_FILE` で場所を指定（`zsh/lib/01.env.sh`）
