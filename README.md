# dotfiles

[mise bootstrap](https://mise.jdx.dev/bootstrap.html) で仕事 / 自宅の端末を同じ構成にするためのリポジトリ。
`~/.config/mise` 自体がこのリポジトリの Git checkout であり、mise のグローバル設定と zsh の runcom をまとめて管理する。

## 管理方針

| 対象 | 担当 |
|---|---|
| `~/.config/mise` の履歴・端末間の共有 | Git（SSH remote） |
| 設定に宣言した状態の端末への配備 | `mise bootstrap` |
| 配備済みファイルの差分確認・copy target の逆取り込み | `mise dot` |

- Git の commit / push を変更管理の正本にする
- `mise dot track` / `sync` / `pull` / `origin` は使わない
- `mise dot` は deployment の確認と、copy したファイルの編集を source に戻す用途に限定する

## ドキュメント

設定の詳細は `docs/` に分かれている。

| ドキュメント | 内容 |
|---|---|
| [config.md](docs/config.md) | リポジトリの構成（各ファイルの役割） |
| [zsh.md](docs/zsh.md) | zsh / prezto の管理分担・編集・設定 |
| [agents.md](docs/agents.md) | コーディングエージェント設定の共通方式 |
| [pi.md](docs/pi.md) / [pig.md](docs/pig.md) / [omp.md](docs/omp.md) / [octet.md](docs/octet.md) / [kilo.md](docs/kilo.md) / [ags.md](docs/ags.md) | 各エージェントの設定 |
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

### 1. adopt — リポジトリを取り込み、端末の役割も同時に選ぶ

自宅PC:

```sh
mise -E personal bootstrap --adopt satoaki-ooto/dotfiles --save-env
```

会社PC:

```sh
mise -E work bootstrap --adopt satoaki-ooto/dotfiles --save-env
```

- `--adopt` はこのリポジトリを `~/.config/mise` の Git checkout として clone し、bootstrap を実行する
- `-E personal` / `-E work` で `config.personal.toml` / `config.work.toml` を最初の実行から読み込む
- `--save-env` は選択した役割を gitignored の `miserc.local.toml` に保存する。
  これにより「共通設定を入れてから、役割を選んで再度 bootstrap」という2段階が不要になる
- `~/.zshrc` / `~/.zsh` の symlink、prezto の clone、共通パッケージがこの実行で揃う
- 役割分のパッケージは、この実行の dotfiles 手順で `~/.config/mise/conf.d/` に symlink される。
  同じ実行の tools 手順でインストールされるかは未確認なので、次で確認し、
  足りなければもう一度 bootstrap する（bootstrap は冪等なので 2 回実行しても問題ない）

  ```sh
  ls ~/.config/mise/conf.d/   # 役割のパッケージの symlink があるか
  mise ls --current           # 役割のツールが出ているか。(missing) があれば次を実行
  mise bootstrap
  ```
- prezto の runcoms（`~/.zlogin` / `~/.zlogout`）も clone 後に自動で symlink され、
  `~/.zpreztorc` / `~/.zshenv` は自前管理版が配備される（管理分担の詳細は [docs/zsh.md](docs/zsh.md)）

`--save-env` が使えない mise の場合は、adopt 後に `miserc.local.toml` を手動作成してから
もう一度 bootstrap する。

```sh
mise bootstrap --adopt satoaki-ooto/dotfiles

printf 'env = ["personal"]\n' > ~/.config/mise/miserc.local.toml   # 自宅PC
# printf 'env = ["work"]\n'    > ~/.config/mise/miserc.local.toml   # 会社PC

mise config   # config.personal.toml（または config.work.toml）が読み込まれていることを確認
mise bootstrap --dry-run && mise bootstrap
```

### 2. 既存ファイルと競合した場合

既存の `~/.zshrc` などがリポジトリ側と食い違うと、adopt は**上書きせずに止まる**。
`mise dot status` と `mise dot diff` で内容を確認し、必要な既存ファイルを退避してから取り込む。

```sh
mise dot status
mise dot diff

# 退避と確認が済んだら、競合する whole-file entry をリポジトリ側で置き換える
mise bootstrap --force-dotfiles
```

- `mise dot pull --take-remote-all` は使わない。
  これは mise の dotfile history（setup repository）向けの操作であり、現在の Git checkout 運用とは別物
- この構成では追跡済みの dotfile history を持たないため、置き換え前の内容は必要なら自分で退避する
- `git status` が汚れている状態で adopt / update すると止まることがある。commit または stash してから実行する

### 3. 秘密情報（sops）を手動で移す

- age 鍵 → `~/.config/sops/age/keys.txt`、secrets → `~/.config/secrets/`
- どちらもリポジトリ外。無くてもシェルは起動する（ローダは存在チェックしてスキップする設計）
- 詳細は [docs/secrets.md](docs/secrets.md)

### 4. 動作確認

```sh
mise doctor
mise bootstrap status
mise dot status
exec zsh   # 新しいシェルで zshrc が読めるか
```

## 端末の役割を選ぶ（personal / work）

共通設定は `config.toml`。端末固有の差分はモジュールとして分かれており、
各端末の `miserc.local.toml` で選択する（**gitignored**: 端末ごとに1回作る）。

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

変更はすべて Git に記録する。

1. このリポジトリ内の source を編集する
2. 必要なら端末へ配備する
3. `git diff` を確認して commit / push
4. 他の端末では `mise bootstrap --update` で反映する

### repo 内の source を編集した場合

`config.toml`、`config.personal.toml`、`agents/`、`zsh/` などを編集する通常のケース。

```sh
# dotfiles の変更を端末へ配備
mise dot diff
mise dot apply

# tools / packages / repos を含めて配備
mise bootstrap

# 変更管理
git diff
git add ...
git commit
git push
```

- `git status` は repo の source と HEAD の差分を見る
- `mise dot diff` は配備先 target と source の差分を見る
- source だけを変更した直後は、`git status` に差分があっても
  `mise dot diff` が `all files are applied` のままのことがある。これは異常ではない
- `mise dot add` は repo 内の設定ファイルを記録するコマンドではない。変更管理は Git で行う

### copy で配備した target を編集した場合

copy 対象は `config.toml` の `mode = "copy"` で宣言されている。

| 配備先 target | repo 内の source |
|---|---|
| `~/.pi/agent/models.json` | `agents/pi/models.json` |
| `~/.pi/agent/AGENTS.md` | `agents/shared/AGENTS.md` |
| `~/.pi/agent/rules/` | `agents/shared/rules/` |
| `~/.pi/agent/extensions/guard-git-push.ts` | `agents/pi/extensions/guard-git-push.ts` |
| `~/.pig/agent/models.json`（macOS）/ `~/.config/pig/agent/models.json`（Linux） | `agents/pig/models.json` |
| `~/.pig/agent/AGENTS.md`（macOS）/ `~/.config/pig/agent/AGENTS.md`（Linux） | `agents/shared/AGENTS.md` |
| `~/.pig/agent/rules/`（macOS）/ `~/.config/pig/agent/rules/`（Linux） | `agents/shared/rules/` |
| `~/.omp/agent/models.yml` | `agents/omp/models.yml` |
| `~/.omp/agent/AGENTS.md` | `agents/shared/AGENTS.md` |
| `~/.omp/agent/rules/` | `agents/shared/rules/` |
| `~/.octet/AGENTS.md` | `agents/shared/AGENTS.md` |
| `~/.octet/rules/` | `agents/shared/rules/` |

ファイルの copy target を直接編集した場合は、差分を source に戻してから Git に記録する。

```sh
mise dot diff

# どの source が更新されるか確認
mise dot add --changed --dry-run

# copy mode のファイルの変更を repo 内の source へ戻す
mise dot add --changed

git diff
git add ...
git commit
git push
```

個別に戻す場合:

```sh
mise dot add ~/.pi/agent/models.json
```

- `mise dot add --changed` は copy mode の通常ファイルが対象。`merge` entry は対象外
- `rules/` のようなディレクトリ copy は、target 側ではなく `agents/shared/rules/` の source を直接編集する
- `AGENTS.md` の source は pi / pig / omp / octet で共通。1つの target から取り込むと全エージェントに影響する
- `dot diff` は配備差分、`git status` は repo の変更を見ている。両方を確認する

### symlink / merge で配備した target

| mode | target を編集したとき |
|---|---|
| `symlink` | target と source が同じ実体なので、repo の変更として `git commit` する |
| `copy` | `mise dot add --changed` で source に戻してから `git commit` する |
| `merge` | repo が管理するキーは source を編集する。アプリが管理するキーは端末ローカルに残す |

`merge` の対象は `settings.json`、`config.yml`、`kilo.jsonc` など。
アプリの UI で変更した値をそのまま repo に取り込むのではなく、repo 側で管理するキーだけを編集する。

## リモートの変更を反映する

既存端末で `origin/main` の変更を取得し、bootstrap まで実行する。

```sh
mise bootstrap --update
```

`--update` は次を行う。

1. `~/.config/mise` の Git checkout を upstream まで fast-forward
2. package metadata と `[bootstrap.repos]`（prezto など）を更新
3. 更新後の設定で bootstrap

dotfiles と shell activation だけを反映する場合:

```sh
mise bootstrap --update --only dotfiles,mise-shell-activate --yes
```

- 日常の更新で `git pull` を別途実行する必要はない
- 明示的にリポジトリを指定する場合は、既存 checkout を再利用する形でも同じことができる:
  `mise bootstrap --adopt satoaki-ooto/dotfiles --update`
- checkout に未コミットの変更があると fast-forward で止まる。commit / stash してから実行する
- `--dry-run` は checkout を更新せず、現在の commit の内容で計画を出す。
  更新後の内容を先に確認したい場合は、`mise bootstrap --update` の後に
  `git log -1` / `git status` と `mise bootstrap status` を確認する
- `mise dot pull` / `mise dot sync` はこの更新には使わない
- 反映後の確認: `mise bootstrap status` / `mise dot status`
- 設定から削除したツールは自動ではアンインストールされない。
  不要になったものは `mise ls --prunable` と `mise prune --dry-run` を確認して別途削除する

## SSH 先の端末へ反映する

SSH 先にも、送信元と同じ Git commit を `--adopt --update` で適用する。

```sh
mise bootstrap remote \
  --host <HOST> \
  --adopt git@github.com:satoaki-ooto/dotfiles.git \
  --remote-env personal \
  --update \
  --dry-run
```

内容を確認したら `--dry-run` を外す。会社PCなら `--remote-env work` にする。

- SSH 先の既存 `~/.config/mise` checkout が再利用され、fast-forward 後に bootstrap が実行される
- 新規ホストでは `--install-mise` を追加する
- `--remote-env` はその実行限りの選択。端末に常設する役割は、そのホストの
  `miserc.local.toml` に保存する
- adopt 済みホストでは `--source` を使わない。
  送信元の一時 project と SSH 先の global config という2経路になり、管理が分かれるため
- `--dry-run` でも SSH 接続、転送、ホストの検査は行われる
- 反映後の確認はホスト上で `mise bootstrap status` / `mise dot status`
