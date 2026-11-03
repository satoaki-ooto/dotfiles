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
- prezto の runcoms（`~/.zlogin` / `~/.zlogout`）も clone 後に自動で symlink され、
  `~/.zpreztorc` / `~/.zshenv` は自前管理版が配備される（下の「zsh の管理分担」）

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
| `zsh/zpreztorc` | `~/.zpreztorc` の実体。prezto の設定（テーマは pure） |
| `zsh/zshenv` | `~/.zshenv` の実体。非対話シェル用の環境整備 |
| `zsh/lib/` | `~/.zsh` の実体。全端末共通の断片 |
| `zsh/personal/`, `zsh/work/` | 役割別の断片。`~/.zsh.personal` / `~/.zsh.work` として deploy |

## zsh

`mise bootstrap` は prezto の clone 後、runcoms を「自分で管理するもの」と
「prezto が管理するもの」に分けて配備する。`~/.zprofile` だけは mise の
shell activation と共存させるため、symlink ではなく source するブロックとして取り込む。
`~/.zpreztorc` は prezto の既定を元にした自前管理版で、テーマは `pure`。
`~/.zshenv` も prezto の `runcoms/zshenv` を元にした自前管理版で、中身は同じ。

### 管理分担

| ファイル | 管理 | 実体 |
|---|---|---|
| `~/.zshrc` | 自分 | `zsh/zshrc`（このリポジトリ） |
| `~/.zsh`, `~/.zsh.<role>` | 自分 | `zsh/lib`, `zsh/personal`, `zsh/work` |
| `~/.zpreztorc` | 自分 | `zsh/zpreztorc`（テーマ pure） |
| `~/.zshenv` | 自分 | `zsh/zshenv` |
| `~/.zlogin` | prezto | `~/.zprezto/runcoms/zlogin` |
| `~/.zlogout` | prezto | `~/.zprezto/runcoms/zlogout` |
| `~/.zprofile` | mise + prezto | mise の activation ブロック + `runcoms/zprofile` を source するブロック |

- 自分側は `[dotfiles]` がこのリポジトリの実体へ、prezto 側は `~/.zprezto/runcoms` の実体へ symlink する
- `~/.zshrc` / `~/.zpreztorc` / `~/.zshenv` は自前版を使うため、prezto の runcoms からは配備しない
- `~/.zprofile` は `[bootstrap.mise_shell_activate]` が書くため symlink できない。
  prezto の zprofile は source するブロックとして足し、内容だけ取り込む
- 状態の確認は `mise dot status`、配備の取り消しは `mise dot unapply`
- prezto 側は symlink なので、`mise bootstrap repos update` で更新すると次のシェルから反映される
- `~/.zprezto` が未 clone の状態では `mise bootstrap --dry-run` は source missing で止まる
  （dry-run は repos を clone しない）。先に `mise bootstrap repos apply` を実行するか、
  そのまま `mise bootstrap` を実行すれば clone 後に配備される
  （source missing になるのは prezto の実体を参照する `~/.zlogin` / `~/.zlogout` だけ。
  `~/.zshenv` は自前管理なので prezto 未 clone でも配備できる）

### 編集

- `~/.zshrc` → `zsh/zshrc`、`~/.zsh` → `zsh/lib`、`~/.zpreztorc` → `zsh/zpreztorc`、
  `~/.zshenv` → `zsh/zshenv` への symlink。編集はどちら側からでも同じ
- [prezto](https://github.com/sorin-ionescu/prezto) は `~/.zprezto` に `[bootstrap.repos]` が clone する（submodules 込み）。更新は `mise bootstrap repos update`
- ローダは `~/.zsh`、続いて `~/.zsh.*`（役割別）を `**/*.zsh` → `**/*.sh` の順で再帰 source。
  役割側が後なので、共通の alias 等を役割別断片で上書きできる
- 役割別断片は `zsh/personal/` / `zsh/work/`。config.personal.toml / config.work.toml が
  `~/.zsh.personal` / `~/.zsh.work` として deploy する
- リポジトリに載せない端末固有の断片は `*.local.sh` / `*.local.zsh`（gitignored）

### prezto の設定（`zsh/zpreztorc`）

- `~/.zpreztorc` は `zsh/zpreztorc` への symlink。prezto の `runcoms/zpreztorc` を元にした自前管理版
- テーマは `pure`（`zstyle ':prezto:module:prompt' theme 'pure'`）。元の既定は `sorin`
- pure のプロンプト記号などは `zsh/lib/98.theme.sh` で調整する（`PURE_PROMPT_SYMBOL`）
- `~/.zprezto` 側の `runcoms/zpreztorc` は編集しない。編集すると `mise bootstrap repos update` が dirty で止まる
- prezto の既定に追従したいときは、`~/.zprezto/runcoms/zpreztorc` と差分を確認してこのファイルへ取り込む

### シェル環境（`zsh/zshenv`）

- `~/.zshenv` は `zsh/zshenv` への symlink。prezto の `runcoms/zshenv` を元にした自前管理版
- 役割は「ログインシェルでも対話シェルでもないとき、`~/.zprofile` を取り込む」こと
  （`SHLEVL` が 1 かつ login でないとき）。`~/.zprofile` には mise の activation と
  prezto の zprofile ブロックが入るので、非対話シェルでも環境変数が揃う
- `~/.zprezto` 側の `runcoms/zshenv` は編集しない。編集すると `mise bootstrap repos update` が dirty で止まる
- prezto の既定に追従したいときは、`~/.zprezto/runcoms/zshenv` と差分を確認してこのファイルへ取り込む

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

## 秘密情報

- sops + age で暗号化。実ファイル（`~/.config/secrets/*.yaml`、age 鍵）は**このリポジトリに含めない**
- 復号鍵は端末ごとに用意し、`SOPS_AGE_KEY_FILE` で場所を指定（`zsh/lib/01.env.sh`）
