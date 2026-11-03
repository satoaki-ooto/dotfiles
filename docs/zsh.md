# zsh

`mise bootstrap` は prezto の clone 後、runcoms を「自分で管理するもの」と
「prezto が管理するもの」に分けて配備する。`~/.zprofile` だけは mise の
shell activation と共存させるため、symlink ではなく source するブロックとして取り込む。
`~/.zpreztorc` は prezto の既定を元にした自前管理版で、テーマは `pure`。
`~/.zshenv` も prezto の `runcoms/zshenv` を元にした自前管理版で、中身は同じ。

## 管理分担

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

## 編集

- `~/.zshrc` → `zsh/zshrc`、`~/.zsh` → `zsh/lib`、`~/.zpreztorc` → `zsh/zpreztorc`、
  `~/.zshenv` → `zsh/zshenv` への symlink。編集はどちら側からでも同じ
- [prezto](https://github.com/sorin-ionescu/prezto) は `~/.zprezto` に `[bootstrap.repos]` が clone する（submodules 込み）。更新は `mise bootstrap repos update`
- ローダは `~/.zsh`、続いて `~/.zsh.*`（役割別）を `**/*.zsh` → `**/*.sh` の順で再帰 source。
  役割側が後なので、共通の alias 等を役割別断片で上書きできる
- 役割別断片は `zsh/personal/` / `zsh/work/`。config.personal.toml / config.work.toml が
  `~/.zsh.personal` / `~/.zsh.work` として deploy する
- リポジトリに載せない端末固有の断片は `*.local.sh` / `*.local.zsh`（gitignored）

## prezto の設定（`zsh/zpreztorc`）

- `~/.zpreztorc` は `zsh/zpreztorc` への symlink。prezto の `runcoms/zpreztorc` を元にした自前管理版
- テーマは `pure`（`zstyle ':prezto:module:prompt' theme 'pure'`）。元の既定は `sorin`
- pure のプロンプト記号などは `zsh/lib/98.theme.sh` で調整する（`PURE_PROMPT_SYMBOL`）
- `~/.zprezto` 側の `runcoms/zpreztorc` は編集しない。編集すると `mise bootstrap repos update` が dirty で止まる
- prezto の既定に追従したいときは、`~/.zprezto/runcoms/zpreztorc` と差分を確認してこのファイルへ取り込む

## シェル環境（`zsh/zshenv`）

- `~/.zshenv` は `zsh/zshenv` への symlink。prezto の `runcoms/zshenv` を元にした自前管理版
- 役割は「ログインシェルでも対話シェルでもないとき、`~/.zprofile` を取り込む」こと
  （`SHLEVL` が 1 かつ login でないとき）。`~/.zprofile` には mise の activation と
  prezto の zprofile ブロックが入るので、非対話シェルでも環境変数が揃う
- `~/.zprezto` 側の `runcoms/zshenv` は編集しない。編集すると `mise bootstrap repos update` が dirty で止まる
- prezto の既定に追従したいときは、`~/.zprezto/runcoms/zshenv` と差分を確認してこのファイルへ取り込む
