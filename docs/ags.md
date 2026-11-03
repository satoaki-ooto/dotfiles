# ags（`agents/ags/` → `~/.config/ags/`）

agent-sandbox（`ags` コマンド）。共通の方式は [agents.md](agents.md)。
設定は TOML 1 ファイルで、pi / pig / omp と同じ merge 方式
（mise は TOML も in-place 編集するのでコメント・キー順は保たれる）。

| ファイル | 手法 | 内容 |
|---|---|---|
| `config.toml` | `merge = true` | 強制するキー（`[sandbox]` の image / パス類 / `passthrough_env` / `extra_dnf_packages`、`[[mount]]`、`[[agent_mount]]`、`[host_ui]` / `[clipboard]` / `[update]`） |
| `config.defaults.toml` | `merge = "missing"` | 既定値だけ配るキー（`[sandbox].enabled_agents`。`ags tools` が書き換えるため） |

- エントリは `config.personal.toml` 直書き（include には `[dotfiles]` を置けないため）
- merge は配列を丸ごと置換する。`[[agent_mount]]` はリポジトリで所有するため
  `ags install --add-agent-mounts` は使わない（足すときは `agents/ags/config.toml` 側へ）
- `ags tools` が書く `[[tool]]`、`tool-downloads.*.lock.json`、`agent-providers.*.lock.json` は管理しない
- `Containerfile` / `image/` / `tmux.conf` / `uv.toml` / `pi/` は ags が実行時に保証する
  アセット（バージョン連動）なので管理しない
- `~/.ssh/ags-agent-auth` / `ags-agent-signing` は `ags setup` が生成する端末ごとの鍵なので管理しない
