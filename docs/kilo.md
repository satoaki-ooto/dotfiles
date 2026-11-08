# kilo（`agents/kilo/` → `~/.config/kilo/kilo.jsonc`）

pi / pig と同じ方式。共通の方式は [agents.md](agents.md)。
kilo の設定は 1 ファイル（`kilo.jsonc`）で、kilo 自身も書き換える
（`/models` でのモデル選択等。`Config.updateGlobal` が jsonc を in-place patch し、
未管理キー・コメントは保たれる）ため merge で管理する。

| ファイル | 手法 | 内容 |
|---|---|---|
| `kilo.jsonc` | `merge = true` | 強制するキー（`default_agent` / `small_model` / `enabled_providers` / `autoupdate` / `share` / 表示系 / `agent.compaction.model` / `agent.orchestrator.disable`） |
| `kilo.defaults.jsonc` | `merge = "missing"` | セッション agent のモデル（`agent.{ask,plan,code,debug}.model`） |

- `agent.{ask,plan,code,debug}.model` は `/models` で選ぶと kilo 側が書き換えるので
  defaults 扱い。無いキーだけ埋める（omp の `modelRoles` と同じ挙動）
- `$schema` は kilo が「無いときだけ追記する」キー。core で常時 `app.kilo.ai` を指す
- 本体（npm:@kilocode/cli）は `packages/kilo.toml`。更新は mise 経由（`kilo upgrade` は使わない）
- `~/.local/share/kilo/`（auth.json / kilo.db）と `~/.cache/kilo/` は管理しない
  （認証情報・セッション DB は端末ローカルのもの）
