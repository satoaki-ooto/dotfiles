# dotfiles

[mise bootstrap](https://mise.jdx.dev/bootstrap.html) で仕事 / 自宅の端末を同じ構成にするためのリポジトリ。
`~/.config/mise` がこのリポジトリへの symlink になっており、mise のグローバル設定と zsh の runcom をまとめて管理する。

## ドキュメント

設定の詳細は `docs/` に分かれている。

| ドキュメント | 内容 |
|---|---|
| [config.md](docs/config.md) | リポジトリの構成（各ファイルの役割） |
| [zsh.md](docs/zsh.md) | zsh / prezto の管理分担・編集・設定 |
| [agents.md](docs/agents.md) | コーディングエージェント設定の共通方式 |
| [pi.md](docs/pi.md) / [pig.md](docs/pig.md) / [omp.md](docs/omp.md) / [kilo.md](docs/kilo.md) / [ags.md](docs/ags.md) | 各エージェントの設定 |
| [secrets.md](docs/secrets.md) | 秘密情報（sops + age）の扱い |

## 新しい端末のセットアップ

**手順は上から順に**。前の段が終わっていないと次は動かないので、各段の確認を通ってから進む。

### 0. 前提（リポジトリに無いものは手動で入れる）

- **git** — adopt がこのリポジトリを clone するのに必要。
  macOS: `xcode-select --install` / Debian系: `sudo apt install git`
- **mise** — `curl -fsSL https://mise.run | sh` の後、`export PATH="$HOME/.local/bin:$PATH"`。
  確認: `mise --version` が新シェルでも通ること
- **GitHub への SSH 認証** — 鍵を作って GitHub に登録し、確認: `ssh -T git@github.com` で `Hi satoaki-ooto!`
  （リポジトリは public なので clone / pull 自体には不要。push 用に必須）
- **コミット署名の設定**（push する側のみ）— `gpg.format = ssh`、`commit.gpgsign = true`、
  `user.signingkey` は端末の global 設定なので、ここで設定する + GitHub に Signing Key 登録
- 既に `~/.config/mise` がある（昔 mise を使っていた）場合は退避:
  `mv ~/.config/mise ~/.config/mise.bak`

### 1. adopt — このリポジトリを `~/.config/mise` に取り込む

```sh
mise bootstrap --adopt satoaki-ooto/dotfiles
```

- 既存の `~/.zshrc` などが食い違うと adopt は**何も適用せずに止まる**（上書きしない）。
  確認して取り込む:
  ```sh
  mise dot status
  mise dot pull --take-remote-all   # 置き換え前の版は保存されるので mise dot undo で戻せる
  mise bootstrap
  ```
- adopt 自体も bootstrap を1回実行するが、**この時点では役割未選択なので共通設定だけ**が入る
- `~/.zshrc` / `~/.zsh` の symlink、prezto の clone、共通パッケージがここまでに揃う
- prezto の runcoms（`~/.zlogin` / `~/.zlogout`）も clone 後に自動で symlink され、
  `~/.zpreztorc` / `~/.zshenv` は自前管理版が配備される（管理分担の詳細は [docs/zsh.md](docs/zsh.md)）

### 2. 役割を選ぶ — `miserc.local.toml` を作る

```sh
printf 'env = ["personal"]\n' > ~/.config/mise/miserc.local.toml   # 自宅PC
# printf 'env = ["work"]\n'    > ~/.config/mise/miserc.local.toml   # 会社PC

mise config   # config.personal.toml（または config.work.toml）が読み込まれていることを確認
```

- このファイルは gitignored なので adopt では来ない。**必ずここで手動作成**
- 詳細は下の「端末の役割を選ぶ」

### 3. もう一度 bootstrap — 役割分（モジュール）を適用

```sh
mise bootstrap --dry-run && mise bootstrap
```

- **adopt だけでは personal / work の分は入らない**。役割選択後に bootstrap を
  走らせて初めて入る（ここを忘れやすい）

### 4. 秘密情報（sops）を手動で移す

- age 鍵 → `~/.config/sops/age/keys.txt`、secrets → `~/.config/secrets/`
- どちらもリポジトリ外。無くてもシェルは起動する（ローダは存在チェックしてスキップする設計）
- 詳細は [docs/secrets.md](docs/secrets.md)

### 5. 動作確認

```sh
mise doctor
exec zsh   # 新しいシェルで zshrc が読めるか
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

## 日々の運用

- 編集はこのリポジトリ内で → `git commit`（SSH 署名は `commit.gpgsign` + `gpg.format=ssh` で自動）→ `git push`
- もう1台への反映は下の「更新を反映する」
- 設定の履歴・差分: `mise dot history` / `mise dot diff`

### 更新を反映する

既存の端末でリモートの変更を反映する。`--adopt` は既存の `~/.config/mise` checkout を
再利用し、`--update` が `origin/main` まで fast-forward してから bootstrap を実行する。

```sh
# dotfiles / zsh の変更だけ反映する
mise bootstrap --adopt satoaki-ooto/dotfiles --update \
  --only dotfiles,mise-shell-activate --yes

# tools / packages / prezto も含めて反映する
mise bootstrap --adopt satoaki-ooto/dotfiles --update --yes
```

- `mise bootstrap --update` 単体では `~/.config/mise` は更新されない
  （`[bootstrap.repos]` の prezto とパッケージメタデータだけが更新される）
- checkout に未コミットの変更があると fast-forward で止まる。commit / stash してから実行する
- `--dry-run` は checkout を更新せず、**現在の commit** の内容で計画を出す。
  更新後の内容を確認したい場合は、先に `git -C ~/.config/mise pull --ff-only` してから
  `mise bootstrap --dry-run` する
- `git pull && mise bootstrap` でも同じ結果になる（mise の外で checkout を更新する場合）
- 反映後の確認: `mise bootstrap status` / `mise dot status`
