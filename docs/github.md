# GitHub

`satoaki-ooto/dotfiles` の `main` ブランチの保護（rulesets）と、履歴改変時の一時的な解除手順。

## main の保護（rulesets）

`protect-main-delete`（id 26912778）と `protect-main-push`（id 26912795）の 2 つの
ruleset で保護する。対象はいずれも default branch（`main`）。

| ruleset | rules | 役割 |
|---|---|---|
| `protect-main-delete` | `deletion` | ブランチ削除の禁止。常時 active。履歴改変に不要なので解除しない |
| `protect-main-push` | `non_fast_forward` + `pull_request` | force push と直 push の禁止。履歴改変時に一時的に disabled にする |

- `pull_request` ルールの required approvals は 0。個人リポジトリなので approve を
  待たずに自分で PR をマージできる（従来の branch protection は approve 1 が最低要件で、
  自分の PR を自分で approve できないため個人 repo では使えない）
- 通常の変更は branch → PR → merge のフロー。main への直 push は不可
- 現在の状態は `gh api repos/satoaki-ooto/dotfiles/rulesets -q '.[] | {id, name, enforcement}'` で確認できる

## 履歴改変時の解除

rebase や `git push --force-with-lease` をするときだけ `protect-main-push` を
disabled にし、終わったら必ず active に戻す。

```sh
# 解除
gh api -X PUT repos/satoaki-ooto/dotfiles/rulesets/26912795 -f enforcement=disabled

# rebase / git push --force-with-lease ...

# 戻す
gh api -X PUT repos/satoaki-ooto/dotfiles/rulesets/26912795 -f enforcement=active
```

- 更新 API は `PUT`（`PATCH` は 404）。`-f enforcement=...` だけの部分更新ができる
- ruleset の変更には repo の owner 権限が必要。個人リポジトリでは ghtkn 経由の
  GitHub App token だと 403 になるため、`GH_COMPANY=0 gh api ...` のように
  keyring 認証の gh を使う。認証方式は呼び出し側で指定する（コマンドに埋め込まない）。
  会社リポジトリで同様の操作をする場合は、その環境の認証に合わせる
