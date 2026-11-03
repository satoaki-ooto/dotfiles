# omp（`agents/omp/` → `~/.omp/agent/`）

pi / pig と同じ方式。共通の方式は [agents.md](agents.md)。
`AGENTS.md` / `rules/` は `agents/shared/` を共有する。
設定ファイルは JSON ではなく YAML（`config.yml` / `models.yml`）で、
merge は YAML を in-place 編集するので未管理キー（`setupVersion` 等）や
コメント・キー順は保たれる。

| ファイル | 手法 | 内容 |
|---|---|---|
| `config.yml` | `merge = true` | 強制するキー（`symbolPreset` / `theme` / `cycleOrder` / `prewalk` / `composer`） |
| `config.defaults.yml` | `merge = "missing"` | 既定値だけ配るキー（`modelRoles` 各ロール / `defaultThinkingLevel`） |
| `models.yml` | `copy` | runinfra の定義のみ。`apiKey: RUNINFRA_GATEWAY_KEY` は env 参照（`${}` 不要な omp 独自記法） |
| `AGENTS.md` / `rules/` | `copy` | `agents/shared/` から。pi / pig と共通 |

- `modelRoles`（smol / slow / plan / commit / task / default）は `/model` で選ぶと
  omp が書き換えるので defaults 扱い。マップはキー単位で比較するため、
  1 ロールだけ変えても他のロールは触られず、消されたロールだけ埋め直る
- `mcp.json` / `RULES.md` は管理していない（`mcp.json` は端末依存の参照を含み、
  `RULES.md` は端末ごとに変える運用のため）
