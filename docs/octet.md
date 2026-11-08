# octet（`agents/shared/` → `~/.octet/`）

pi / pig / omp と同じ方式。共通の方式は [agents.md](agents.md)。
`AGENTS.md` / `rules/` は `agents/shared/` を共有する。
octet 自身の設定（`~/.octet/config.toml` / `credentials/`）はアプリが管理する
（`config.toml.lock` 付き）ので管理対象外。

| ファイル | 手法 | 内容 |
|---|---|---|
| `AGENTS.md` / `rules/` | `copy` | `agents/shared/` から。pi / pig / omp と共通 |

- `~/.octet/AGENTS.md` はグローバルコンテキストファイル。workspace の信頼
  （`--workspace-trusted`）が無くても毎回 system prompt に合成される。
  `<project_instructions path="...">` ブロックでパス付き、root → leaf 順
- `AGENTS.md` の `@rules/...` は octet に rules 専用の合成機構が無いため、
  モデルが `read` ツールで `~/.octet/rules/` を読んで解決する。
  `--safe-mode` 起動時は workspace 外の read が無効になるため解決できない
- 反映は `mise dot apply` の後、octet 側で `/reload`
