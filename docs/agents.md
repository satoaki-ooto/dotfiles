# コーディングエージェントの設定

各エージェントの設定は `agents/<agent>/` に置き、`[dotfiles]` で deploy する。
`AGENTS.md` と `rules/` は「全エージェントで共通」という位置づけなので `agents/shared/` に
1 箇所だけ置き、各エージェントから参照する。
エージェント自身が書き換えるファイルは `merge` で「自分のキー」だけ管理し、
そうでないものは `copy`（実ファイル）にする。symlink だと sandbox 内で
`~/.config/mise` が見えず設定を読めないため。

- [pi](pi.md)（`agents/pi/` → `~/.pi/agent/`）
- [pig](pig.md)（`agents/pig/` → `~/.config/pig/agent/`）
- [omp](omp.md)（`agents/omp/` → `~/.omp/agent/`）
- [ags](ags.md)（`agents/ags/` → `~/.config/ags/`）
