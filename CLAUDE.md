# CLAUDE.md

Windows 11 + Rancher Desktop 上の Docker 開発環境 dotfiles。実際の開発はコンテナ `devenv`（Ubuntu 24.04, Neovim + tmux + zsh）内で行う。

## アーキテクチャの不変条件（変更時に必ず守る）

- **`/home/dev` は単一 named volume `devenv_home` で永続化**されている。volume はイメージから**初回マウント時に一度だけ** seed されるため、**Dockerfile で `/home/dev` にツール実体を置かないこと**（骨格ディレクトリの pre-create のみ可）。イメージ側の seed 置き場は `/opt`（例: `/opt/zinit`）。
- ユーザー空間ツールの追加は `docker/bootstrap.sh` に「実物の有無で判定する冪等ステップ」を足す。マーカーファイル方式は禁止（失敗時に再試行されなくなるため）。
- システムツール（全ユーザー共通・バージョン固定）は Dockerfile で `/usr/local` 等へ。apt はバージョンピンしているため、rebuild が 404 で落ちたら該当 ARG のピンを最新の Candidate に更新する。
- `~/.zshrc` などはリポジトリへの **symlink**。コンテナ内でインストーラーが `~/.zshrc` に追記すると**リポジトリ実体が汚れる**。見つけたら即削除する（PATH 追記は `.zshrc` 冒頭で設定済み）。
- git の個人設定（user.name/email）は `docker/.env` が唯一の情報源。`bootstrap.sh` が毎起動時に `~/.gitconfig.local` を再生成し、`git/.gitconfig` の `[include]` が読む。
- **このホストの Docker には他プロジェクト（Dify / k8s）が同居している。`docker volume prune` / `docker system prune` は絶対に使わない**。volume 操作は明示的な名前指定のみ。
- `docker compose down -v` は全状態（Claude ログイン・履歴・プラグイン）を消すファクトリーリセット。提案する場合は必ず警告する。

## 日常コマンド

```powershell
.\scripts\Start-Docker.ps1            # 起動して tmux セッション main へ
.\scripts\Start-Docker.ps1 -Rebuild   # イメージ再ビルド + コンテナ再作成（状態は残る）
docker restart devenv                  # entrypoint/bootstrap の変更反映
docker exec -u dev devenv bash /home/dev/workspace/dotfiles/docker/smoke-test.sh  # 検証
```

- 設定ファイル（shell/ git/ neovim/ tmux/ lazygit/）の変更は symlink 経由で即反映。rebuild 不要。
- Antigravity CLI のバイナリ名は `antigravity` ではなく **`agy`**。

## 検証方法

変更後は smoke-test に加え、「永続性」を確認する: `docker compose -f docker/docker-compose.yml down` → `up -d` 後も `~/.local/bin/claude` とログイン状態が残っていること（bootstrap の Installing ログが出ないこと）。

## 既知の残課題

- docker.sock をマウントしているがイメージに docker CLI が無い（DooD 未完成）。
