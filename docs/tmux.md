# tmux

`~/.tmux.conf` をこのリポジトリの `tmux/tmux.conf` への symlink として管理する。
`tmux` 本体とプラグイン（`~/.tmux/plugins/`）はこのリポジトリの対象外。

## 管理分担

| 対象 | 管理 | 実体 |
|---|---|---|
| `~/.tmux.conf` | 自分（symlink） | `tmux/tmux.conf`（このリポジトリ） |
| `~/.tmux/plugins/` | TPM | 各端末ローカル（リポジトリ対象外） |

- `~/.tmux.conf` は `tmux/tmux.conf` への symlink。編集はどちら側からでも同じ
- 編集後の反映は tmux 内で `C-t r`（または `tmux source-file ~/.tmux.conf`）

## 新しい端末のセットアップ

`tmux`（3.5 以上推奨。`extended-keys-format csi-u` は 3.5 以上でのみ有効になる）をインストールしたうえで、[TPM](https://github.com/tmux-plugins/tpm) を clone してプラグインを入れる。

```sh
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```

その後 tmux を起動し、`C-t I`（Prefix + `I`）で `tmux/tmux.conf` に宣言されたプラグイン（`catppuccin/tmux` / `tmux-floax` / `tmux-resurrect` / `tmux-continuum`）をインストールする。

- `catppuccin/tmux` v2 は `run '~/.tmux/plugins/tmux/catppuccin.tmux'` で明示的に読み込んでいるため、初回起動時（`C-t I` 実行前）はファイル未存在のエラーが出るが、末尾の TPM は読み込まれるのでそのまま `C-t I` を実行すれば解消する

## 既存の `~/.tmux.conf` からの移行

既存の `~/.tmux.conf`（通常ファイルや別リポジトリへの symlink）がある端末では、`mise bootstrap --update` は上書きせず競合で止まる。
内容を確認し、必要なら退避してから `~/.tmux.conf` だけ適用する（`mise bootstrap --force-dotfiles` は他の競合ファイルも一括で上書きするため使わない）。

```sh
mise dot status
mise dot diff
mv -i ~/.tmux.conf ~/.tmux.conf.bak   # 既存のバックアップと重複しない名前にする
mise dot apply '~/.tmux.conf'
```
