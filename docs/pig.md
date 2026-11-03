# pig（`agents/pig/` → `~/.config/pig/agent/`）

pi と同じ方式（詳細は [pi.md](pi.md)）。共通の方式は [agents.md](agents.md)。
`AGENTS.md` / `rules/` は `agents/shared/` を共有する。

| ファイル | 手法 | 内容 |
|---|---|---|
| `settings.json` | `merge = true` | 強制するキー（`theme` / `enableAnalytics`） |
| `settings.defaults.json` | `merge = "missing"` | 既定値だけ配るキー（`defaultProvider` / `defaultModel`） |
| `models.json` | `copy` | runinfra の定義。pi の `models.json` と中身は別物（pig は `models.json` のみ読む） |
| `AGENTS.md` / `rules/` | `copy` | `agents/shared/` から。pi と共通 |

- pig の設定 root は `PIG_HOME` → `XDG_CONFIG_HOME` → `~/.pig` の順で決まる。
  `config.personal.toml` の `[env]` で `PIG_HOME` を固定しているので、
  `XDG_CONFIG_HOME` が無い環境（sandbox 等）でも `~/.config/pig` を見に行く
- pig は `models.json` だけを読み、`models.jsonc` は参照しない。
  手元に `models.jsonc` が残っていても無効（`[dotfiles]` の `absent` で消している）。
  「pig が provider を見つけられない」原因はほぼこれ
- pig は `PIG_USE_PI_DIRS=1` で pi の `~/.pi/agent` を共有できるが、
  sessions / auth / trust も共有されるため使っていない（分離が pig の既定動作）
