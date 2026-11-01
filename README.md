# dotfiles

[mise bootstrap](https://mise.jdx.dev/bootstrap.html) で仕事 / 自宅の端末を同じ構成にするためのリポジトリ。
`~/.config/mise` がこのリポジトリへの symlink になっており、mise のグローバル設定と zsh の runcom をまとめて管理する。

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

## 構成

| ファイル | 役割 |
|---|---|
| `config.toml` | 全端末共通（tools / packages / prezto clone / dotfiles 宣言） |
| `config.personal.toml` | 自宅PC向け（`env = ["personal"]` で読み込まれる） |
| `config.work.toml` | 会社PC向け（`env = ["work"]` で読み込まれる） |
| `miserc.local.toml` | 端末ごとの役割選択（gitignored、同期されない） |
| `zsh/zshrc` | `~/.zshrc` の実体（prezto の init 読み込み + ローダ） |
| `zsh/lib/` | `~/.zsh` の実体。全端末共通の断片 |
| `zsh/personal/`, `zsh/work/` | 役割別の断片。`~/.zsh.personal` / `~/.zsh.work` として deploy |

## zsh

- `~/.zshrc` → `zsh/zshrc`、`~/.zsh` → `zsh/lib` への symlink。編集はどちら側からでも同じ
- [prezto](https://github.com/sorin-ionescu/prezto) は `~/.zprezto` に `[bootstrap.repos]` が clone する（submodules 込み）。更新は `mise bootstrap repos update`
- ローダは `~/.zsh`、続いて `~/.zsh.*`（役割別）を `**/*.zsh` → `**/*.sh` の順で再帰 source。
  役割側が後なので、共通の alias 等を役割別断片で上書きできる
- 役割別断片は `zsh/personal/` / `zsh/work/`。config.personal.toml / config.work.toml が
  `~/.zsh.personal` / `~/.zsh.work` として deploy する
- リポジトリに載せない端末固有の断片は `*.local.sh` / `*.local.zsh`（gitignored）

## 日々の運用

- 編集はこのリポジトリ内で → `git commit`（SSH 署名は `commit.gpgsign` + `gpg.format=ssh` で自動）→ `git push`
- もう1台は `git pull`（symlink 先が更新される）。tools / packages の変更が入ったら `mise bootstrap`
- 設定の履歴・差分: `mise dot history` / `mise dot diff`

## 秘密情報

- sops + age で暗号化。実ファイル（`~/.config/secrets/*.yaml`、age 鍵）は**このリポジトリに含めない**
- 復号鍵は端末ごとに用意し、`SOPS_AGE_KEY_FILE` で場所を指定（`zsh/lib/01.env.sh`）
