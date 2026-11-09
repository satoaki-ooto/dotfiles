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

## エンドポイントの追加（custom provider）

endpoint の追加は octet 自身の管理領域（`~/.octet/`）への操作なので、
repo では手順だけを残す。追加先は custom registry の
`~/.octet/credentials/custom.json`（権限 `600`）。追加したモデルは
`custom/<provider-id>/<model-id>` という ID で選ぶ。

- `octet setup` で追加するのが基本。endpoint と credential の出所を指定し、
  レビュー画面で確認してから保存する（保存するまでは何も書かれない）
  - `octet setup --endpoint <endpoint URL> --api-key-env <環境変数名>`
  - LM Studio は `octet setup --preset lm-studio --manual-model <model ID>`
  - probe（`GET /models`）も送らせない場合は
    `--offline --manual-model <model ID>` を付ける
  - TUI の `/setup` からも同じ追加・削除ができる
- `custom.json` を直接書く場合は、キーを literal で書かず env 参照にする

  ```json
  {
    "version": 1,
    "providers": {
      "example": {
        "label": "Example",
        "base_url": "http://127.0.0.1:8000/v1/",
        "auth": { "kind": "bearer_env", "var": "EXAMPLE_API_KEY" },
        "auto_discover": true
      }
    }
  }
  ```

  - 認証なしは `"auth": { "kind": "none" }`
  - `"auto_discover": true` なら `GET /v1/models` でモデルを発見する。
    discovery が使えない endpoint では `false` にして `models` を明示する
- provider の既定は OpenAI Chat Completions 互換。Anthropic 互換の gateway は
  `"api": "anthropic-messages"`、Responses 互換は
  `"api": "openai-responses"` を付ける。この2種は `auto_discover` の
  対象外で、`models` の宣言が要る
- 追加後の確認は、`/model` で `custom/...` が選べることと、
  `/status` で経路が想定どおりであること
- この repo は public。実際の endpoint URL や環境変数名はここに書かず、
  例は placeholder に留める。実値は端末の `custom.json` と環境変数だけに置く
- 認証情報は `~/.octet/config.toml` にも書かない
