# 秘密情報

- sops + age で暗号化。実ファイル（`~/.config/secrets/*.yaml`、age 鍵）は**このリポジトリに含めない**
- 復号鍵は端末ごとに用意し、`SOPS_AGE_KEY_FILE` で場所を指定（`zsh/lib/01.env.sh`）
