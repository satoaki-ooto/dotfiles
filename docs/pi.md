# pi（`agents/pi/` → `~/.pi/agent/`）

共通の方式は [agents.md](agents.md)。

| ファイル | 手法 | 内容 |
|---|---|---|
| `settings.json.tera` | `merge = true` + template | 強制するキー（`theme` / `extensions` / `packages`） |
| `settings.defaults.json` | `merge = "missing"` | 既定値だけ配るキー（`defaultProvider` / `defaultModel` / `defaultThinkingLevel`） |
| `models.json` | `copy` | 互換エンドポイントとモデル。API キーは `${RUNINFRA_GATEWAY_KEY}` の env 参照 |
| `AGENTS.md` | `copy` | 全プロジェクト共通の指示（`agents/shared/` から） |
| `rules/` | `copy` | `AGENTS.md` から `@rules/*.md` で読まれる断片（`agents/shared/rules/` から） |
| `extensions/guard-git-push.ts` | `copy` | main/master への `git push` をツール実行前に止める拡張（自動検出） |

- `settings.json` は pi 自身も書き換える（`/settings`、`pi install`、アップグレード時の
  `lastChangelogVersion` 更新）。`merge` にすることで pi の持つキーは壊さない
- `merge = true` のキーはリポジトリが唯一の情報源。`pi install` した拡張は
  `agents/pi/settings.json.tera` に書いてから `mise bootstrap` すると全機械に反映される
  （書かないと次の bootstrap で元に戻る）
- `merge = "missing"` のキーは `/model` で選んだ値を pi の所有物として扱う。
  新しい端末では settings.json が無いので既定値が入り、`pi install` 直後から使える
- `copy` のファイル（`models.json` / `AGENTS.md` / `rules/`）はターゲット側を編集すると
  次の apply で上書きされる。編集は `agents/` 側で行い `mise dot apply` で反映する。
  ターゲット側で編集した内容を取り込むときは `mise dot add ~/.pi/agent/AGENTS.md` のようにする
  （ drift は `mise dot diff` で見える）
- `{{ env.HOME }}` で絶対パスを展開するため、macOS（`/Users/...`）でも同じ source が使える
- 管理しないもの: `auth.json`（資格情報。sops の `~/.config/secrets/` から env で渡す）、
  `trust.json`（端末固有のパス）、`sessions/`、`bin/`、`install/`、`models-store.json`（キャッシュ）
- `extensions/` は pi の自動検出対象なので、`settings.json` の `extensions` に書かなくても読まれる
- `guard-git-push.ts` は bash ツールの `tool_call` を横取りし、push 先の refspec を解決して
  main/master を更新する push をブロックする。Claude Code の PreToolUse フック相当
  - `git push origin HEAD`（main 上）、`git push origin feat:main`、`--all` / `--mirror`、
    ワイルドカード refspec も対象
  - 現在ブランチを解決できないときは fail closed（`HEAD` への push を拒否）
  - 完全なシェルパースはしない（変数展開・alias は対象外）。GitHub の branch protection と併用する
  - ユーザーが `!` で直接打つコマンド（`user_bash`）は対象外
- `settings.json.tera` の `-extensions/guard.ts` は ags がマウントする別の guard を無効化するもの。
  `guard-git-push.ts` とは別ファイル
- `models.jsonc` は pi が読まない（pi は `models.json` のみ）。手元に残っていても無効
- `models.json` はリポジトリに載せてよい（API キーは `${RUNINFRA_GATEWAY_KEY}` の env 参照で、
  実値は sops の `~/.config/secrets/` 経由）。ただし provider 定義が無いと pi は起動しない
  （`defaults` が `defaultProvider` を配るため）。リポジトリに載せたくない場合は
  fnox（`mode = "fnox"` で age 暗号化配布）か sops + bootstrap task への移行を検討する
