# herdr

`~/.config/herdr/config.toml` と `herdr-worktrunk` プラグインの設定（`~/.config/herdr/plugins/config/worktrunk/config.toml`）をこのリポジトリからの symlink として管理する。
`herdr` 本体・プラグイン本体（`~/.config/herdr/plugins/github/`）・ランタイム状態（`plugins.json` / `session.json` / ログ / ソケット類）はこのリポジトリの対象外。

## 管理分担

| 対象 | 管理 | 実体 |
|---|---|---|
| `~/.config/herdr/config.toml` | 自分（symlink） | `herdr/config.toml`（このリポジトリ） |
| `~/.config/herdr/plugins/config/worktrunk/config.toml` | 自分（symlink） | `herdr/plugins/worktrunk/config.toml`（このリポジトリ） |
| `~/.config/herdr/plugins/github/` | `herdr plugin`（`[tasks.bootstrap]` で自動導入・有効化） | 各端末ローカル（リポジトリ対象外） |
| `~/.config/herdr/{plugins.json,session.json,*.log,*.sock}` など | herdr ランタイム | 各端末ローカル（リポジトリ対象外） |

- `~/.config/herdr/config.toml` / `~/.config/herdr/plugins/config/worktrunk/config.toml` はそれぞれリポジトリ内ファイルへの symlink。編集はどちら側からでも同じ
- `herdr/config.toml` 編集後の構文・整合確認は `herdr config check`、稼働中のサーバーへの反映は `herdr server reload-config`（または herdr 内で `Ctrl+o Shift+R`）
- `herdr/plugins/worktrunk/config.toml` は picker 起動ごとに読まれるため、編集後のリロードは不要
- herdr の UI 操作や `herdr channel set` などで `config.toml` が書き換わった場合も symlink 先に反映されるため、`git diff` で確認して取り込むか戻すかを判断する

## 新しい端末のセットアップ

`herdr` 本体と、`herdr-worktrunk` が依存するツール（`wt`（worktrunk）/ `fzf` / `bash`。`jq` は `packages/jq.toml` で管理）を用意したうえで `mise bootstrap` を実行する。

- `config.toml` の `[tasks.bootstrap]` が `herdr` コマンドの存在を確認し、[devashish2203/herdr-worktrunk](https://github.com/devashish2203/herdr-worktrunk) が未導入なら `herdr plugin install devashish2203/herdr-worktrunk --yes` で自動導入する
- 既に `worktrunk` が導入済みなら再インストールせずそのまま維持する。無効化（`disabled`）されている場合は、herdr サーバー稼働中なら `herdr plugin enable worktrunk` で有効化する（未起動時は案内を出してスキップ）
- `herdr` 未導入の端末では `[tasks.bootstrap]` は何もせず終了する
- `mise dot apply` 単体では `[tasks.bootstrap]` は実行されない。プラグイン導入だけ実行したい場合は `mise bootstrap --only task` を使う
- `herdr/config.toml` では `[worktrees].directory` に `~/Workspace/repos/worktrees.herdr` を指定している

## 既存の `~/.config/herdr/` 設定からの移行

既存の `~/.config/herdr/config.toml` や `~/.config/herdr/plugins/config/worktrunk/config.toml`（通常ファイルや別リポジトリへの symlink）がある端末では、`mise bootstrap --update` は上書きせず競合で止まる。
内容を確認し、必要なら退避してから対象ファイルだけ適用する（`mise bootstrap --force-dotfiles` は他の競合ファイルも一括で上書きするため使わない）。

```sh
mise dot status
mise dot diff
mv -i ~/.config/herdr/config.toml ~/.config/herdr/config.toml.bak   # 既存のバックアップと重複しない名前にする
mv -i ~/.config/herdr/plugins/config/worktrunk/config.toml ~/.config/herdr/plugins/config/worktrunk/config.toml.bak
mise dot apply '~/.config/herdr/config.toml' '~/.config/herdr/plugins/config/worktrunk/config.toml'
```
