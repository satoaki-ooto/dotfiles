# herdr

`~/.config/herdr/config.toml` をこのリポジトリの `herdr/config.toml` への symlink として管理する。
`herdr` 本体・プラグイン（`~/.config/herdr/plugins/`）・ランタイム状態（`plugins.json` / `session.json` / ログ / ソケット類）はこのリポジトリの対象外。

## 管理分担

| 対象 | 管理 | 実体 |
|---|---|---|
| `~/.config/herdr/config.toml` | 自分（symlink） | `herdr/config.toml`（このリポジトリ） |
| `~/.config/herdr/plugins/` | `herdr plugin` | 各端末ローカル（リポジトリ対象外） |
| `~/.config/herdr/{plugins.json,session.json,*.log,*.sock}` など | herdr ランタイム | 各端末ローカル（リポジトリ対象外） |

- `~/.config/herdr/config.toml` は `herdr/config.toml` への symlink。編集はどちら側からでも同じ
- 編集後の構文・整合確認は `herdr config check`、稼働中のサーバーへの反映は `herdr server reload-config`（または herdr 内で `Ctrl+o Shift+R`）
- herdr の UI 操作や `herdr channel set` などで `config.toml` が書き換わった場合も symlink 先に反映されるため、`git diff` で確認して取り込むか戻すかを判断する

## 新しい端末のセットアップ

`herdr` 本体をインストールしたうえで、`herdr/config.toml` の `[[keys.command]]` で参照している `worktrunk` プラグイン（[devashish2203/herdr-worktrunk](https://github.com/devashish2203/herdr-worktrunk)）と依存ツール（`wt`（worktrunk）/ `fzf` / `jq` / `bash`）を導入する。

```sh
herdr plugin install devashish2203/herdr-worktrunk
```

- プラグイン未インストールでも herdr 自体は起動できるが、`worktrunk.*` のキーバインドはプラグイン導入後に有効になる
- `herdr/config.toml` では `[worktrees].directory` に `~/Workspace/repos/worktrees.herdr` を指定している

## 既存の `~/.config/herdr/config.toml` からの移行

既存の `~/.config/herdr/config.toml`（通常ファイルや別リポジトリへの symlink）がある端末では、`mise bootstrap --update` は上書きせず競合で止まる。
内容を確認し、必要なら退避してから `~/.config/herdr/config.toml` だけ適用する（`mise bootstrap --force-dotfiles` は他の競合ファイルも一括で上書きするため使わない）。

```sh
mise dot status
mise dot diff
mv -i ~/.config/herdr/config.toml ~/.config/herdr/config.toml.bak   # 既存のバックアップと重複しない名前にする
mise dot apply '~/.config/herdr/config.toml'
```
