# pig（`agents/pig/` → OS ごとの設定 root。macOS: `~/.pig/agent`、Linux: `~/.config/pig/agent`）

pi と同じ方式（詳細は [pi.md](pi.md)）。共通の方式は [agents.md](agents.md)。
`AGENTS.md` / `rules/` は `agents/shared/` を共有する。

| ファイル | 手法 | 内容 |
|---|---|---|
| `settings.json` | `merge = true` | 強制するキー（`theme` / `enableAnalytics`） |
| `settings.defaults.json` | `merge = "missing"` | 既定値だけ配るキー（`defaultProvider` / `defaultModel`） |
| `models.json` | `copy` | runinfra の定義。pi の `models.json` と中身は別物（pig は `models.json` のみ読む） |
| `AGENTS.md` / `rules/` | `copy` | `agents/shared/` から。pi と共通 |

- pig の設定 root は pig が `PIG_HOME` → `XDG_CONFIG_HOME` → `~/.pig` の順で決める。
  配備先と pig の読み先を確実に一致させるため、`config.macos.toml` / `config.linux.toml` の
  `[env]` で OS ごとに `PIG_HOME` を固定し、同じファイルの `[dotfiles]` がその配下に
  配備する（macOS: `~/.pig/agent`、Linux: `~/.config/pig/agent`。中身は OS 間で共通）。
  `XDG_CONFIG_HOME` より `PIG_HOME` が優先されるため、上記で固定した root が使われる
- 旧来 `~/.config/pig` に配備していた macOS 端末の移行: この変更を取り込んだ後
  `mise dot apply`（または `mise bootstrap`）で `~/.pig` 側へ配備し直す。
  pig の sessions / auth / trust は配置対象外なので、引き継ぐなら手動で移す。
  旧 `~/.config/pig` は mise の管理外に残るため、不要になったら手動で削除する
- pig は `models.json` だけを読み、`models.jsonc` は参照しない。
  手元に `models.jsonc` が残っていても無効（各 OS ファイルの `absent` で消している）。
  「pig が provider を見つけられない」原因はほぼこれ
- pig は `PIG_USE_PI_DIRS=1` で pi の `~/.pi/agent` を共有できるが、
  sessions / auth / trust も共有されるため使っていない（分離が pig の既定動作）
