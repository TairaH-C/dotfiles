# dotfiles

Docker 上で完結する Neovim + tmux + zsh 開発環境。エディタ・tmux・lazygit は Catppuccin Mocha、starship プロンプトは Gruvbox Powerline で統一されたモダン CLI 構成。

**設計の核心**: コンテナ内の `/home/dev` 全体を単一の named volume（`devenv_home`）で永続化している。Claude Code のログイン状態・シェル履歴・プラグイン・各ツールの設定など、**すべての状態がコンテナの再作成やイメージの再ビルドを跨いで保持される**。

## 構成

```text
dotfiles/
├── docker/
│   ├── Dockerfile            # Ubuntu 24.04 開発イメージ（システムツールのみ）
│   ├── docker-compose.yml    # home volume 永続化・env 注入
│   ├── entrypoint.sh         # root: 所有権修正 → bootstrap 呼び出し
│   ├── bootstrap.sh          # dev: symlink / AI CLI / プラグインを冪等に整備
│   ├── smoke-test.sh         # 環境検証スクリプト
│   └── .env.example          # API キー・git 個人設定のテンプレート
├── scripts/
│   ├── Start-Docker.ps1      # ★ 日常の起動入口（Rancher 起動 → up -d → tmux）
│   ├── setup-symlinks.sh     # シンボリックリンク作成（コンテナ内）
│   ├── windows-setup.ps1     # Windows 初期セットアップ（winget 一括導入）
│   └── disk-management.ps1   # WSL2 / Docker ディスク管理
├── shell/                    # .zshrc / .aliases / starship.toml
├── git/                      # .gitconfig / .gitignore_global
├── neovim/nvim/              # init.lua + lua/config + lua/plugins
├── tmux/                     # .tmux.conf（C-Space prefix, Catppuccin）
├── lazygit/                  # config.yml
├── docs/                     # KEYBINDINGS.md / TECH-STACK.md
├── CLAUDE.md                 # Claude Code 向けリポジトリガイド
└── .wslconfig.template       # ~/.wslconfig の雛形
```

## 日常の使い方

Windows Terminal のプロファイルに以下を設定しておく（または PowerShell から直接実行）:

```powershell
powershell.exe -ExecutionPolicy Bypass -NoExit -File "C:\Users\<you>\workspace\dotfiles\scripts\Start-Docker.ps1"
```

これ 1 つで「Rancher Desktop 起動 → Docker 待機 → コンテナ起動（なければ作成）→ tmux セッション `main` にアタッチ」まで行う。前回の tmux セッションがあればそのまま続きから作業できる。

```powershell
# プレーンな zsh で入りたいとき
.\scripts\Start-Docker.ps1 -NoTmux

# イメージを再ビルドしてコンテナを作り直す（状態は home volume に残るので安全）
.\scripts\Start-Docker.ps1 -Rebuild
```

## 状態の永続化モデル

| 対象 | 方式 | 内容 |
|------|------|------|
| `/home/dev` 全体 | named volume `devenv_home` | Claude Code 本体とログイン、zsh 履歴、nvim / tmux / zinit プラグイン、zoxide DB、uv キャッシュなど**すべて** |
| `~/workspace` | bind mount | Windows 側 `%USERPROFILE%\workspace`（実体は Windows に保存） |
| `~/.ssh` | bind mount (読み取り専用) | ホストの SSH 鍵 |
| `~/.config/github-copilot` | bind mount (読み取り専用) | ホスト側で認証済みの Copilot 資格情報 |
| `docker.sock` / ssh-agent | bind mount | ホスト連携 |

初回起動時に `bootstrap.sh` が Claude Code / Antigravity CLI / プラグイン類を home volume にインストールする。判定は「実物があるか」なので、失敗しても次回起動時に自動リトライされ、成功後は二度と走らない。AI CLI はそれぞれの自己アップデート機構で更新される。

### 変更の反映方法

| 変更したもの | 反映方法 |
|--------------|----------|
| `shell/` `git/` `neovim/` `tmux/` などの設定 | symlink なので保存即反映（シェルは開き直し） |
| `entrypoint.sh` / `bootstrap.sh` | `docker restart devenv`（bind mount のため rebuild 不要） |
| `Dockerfile` / `docker-compose.yml` | `.\scripts\Start-Docker.ps1 -Rebuild` |

### バックアップとファクトリーリセット

```powershell
# home volume のバックアップ（リポジトリルートで実行）
docker run --rm -v devenv_home:/src:ro -v "${PWD}:/backup" alpine tar czf /backup/devenv-home-backup.tgz -C /src .

# ⚠ ファクトリーリセット: Claude ログイン・履歴・プラグインなど全状態が消える
docker compose -f docker\docker-compose.yml down -v
```

`down`（`-v` なし）はコンテナを破棄するだけで、状態は volume に残る。

## 初期セットアップ（新しいマシン）

### 1. Windows ツールの一括導入

**通常の（非管理者）PowerShell** から:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\windows-setup.ps1
```

UAC 1 回で管理者必須パッケージ（Office / Rancher Desktop / Azure CLI / SSMS / PowerShell 7 / PlemolJP フォント等）を先に入れ、続いてユーザースコープ（Windows Terminal / VS Code / uv / Git / Node / Go 等）を導入する。オプション: `-DryRun` / `-SkipAdminPackages` / `-Force`。

### 2. WSL2 と Rancher Desktop

```powershell
wsl --install   # 管理者 PowerShell。実行後に再起動
```

Rancher Desktop 初回起動時: Container Engine で **dockerd (moby)** を選択し、WSL Integration を有効化。必要なら `~/.wslconfig` を `.wslconfig.template` から作成。

### 3. Windows Terminal の設定

- フォントを `PlemolJP Console NF` に変更（Nerd Font でないとアイコンが豆腐になる）
- Actions で「Allow OSC 52 clipboard access」を有効化（tmux からのクリップボード連携）

### 4. リポジトリと個人設定

```powershell
git clone https://github.com/TairaH-C/dotfiles.git $env:USERPROFILE\workspace\dotfiles
cd $env:USERPROFILE\workspace\dotfiles
copy docker\.env.example docker\.env
# docker\.env を編集: GIT_USER_NAME / GIT_USER_EMAIL（必須）、API キー（任意）
```

### 5. 起動

```powershell
.\scripts\Start-Docker.ps1
```

初回はイメージビルドが走らないため、先に `.\scripts\Start-Docker.ps1 -Rebuild` を使うか `docker compose -f docker\docker-compose.yml build` を実行しておく。初回起動時は bootstrap（プラグイン・AI CLI のインストール）に数分かかる。完了後、コンテナ内で `claude` を実行してログインすれば、**以後ログイン状態は永続する**。

### 6. 動作確認

```powershell
docker exec -u dev devenv bash /home/dev/workspace/dotfiles/docker/smoke-test.sh
```

## tmux

プレフィックスキーは `C-Space`。詳細は [docs/KEYBINDINGS.md](docs/KEYBINDINGS.md)。

| キー | 動作 |
|------|------|
| `C-Space \|` / `C-Space -` | 縦 / 横分割（カレントパス） |
| `C-h/j/k/l` | ペイン移動（Neovim 分割とシームレス連携） |
| `C-Space D` | 開発レイアウト: Neovim（左 65%）+ Claude Code（右上）+ ターミナル（右下） |
| `C-Space A` | エージェントレイアウト: 3 ペイン均等分割 |

コピーモードは vi キーバインド（`v` 選択、`y` コピー、OSC 52 で Windows クリップボードへ）。tmux-resurrect + continuum が 15 分ごとにセッションを自動保存する。

## Neovim

リーダーキーは `Space`。押して待つと which-key が全コマンドを表示する。VS Code との対応表を含むキーマップ一覧は [docs/KEYBINDINGS.md](docs/KEYBINDINGS.md)、プラグイン構成は [docs/TECH-STACK.md](docs/TECH-STACK.md) を参照。

- LSP: Python (basedpyright + ruff) / TypeScript / Lua / JSON / YAML / Bash / TOML など 8 言語。保存時自動フォーマット（conform.nvim）
- `<leader>gg` で LazyGit、`<leader>cc` で Claude Code ターミナル
- Copilot はホスト側で認証済みの資格情報を read-only マウントで利用する（コンテナ内での `:Copilot auth` は不可）

## シェル (zsh)

zinit 管理のプラグイン（autosuggestions / syntax-highlighting / completions）+ zoxide + fzf + starship。主なエイリアス: `ls`→eza、`cat`→bat、`grep`→rg、`find`→fd、`vi/vim`→nvim、`lg`→lazygit。

## Git

- pager は delta（side-by-side、Catppuccin）。pull は rebase、push は `autoSetupRemote`
- **個人設定（user.name / user.email）は `docker/.env` が唯一の情報源**。起動時に `bootstrap.sh` が `~/.gitconfig.local` を生成し、`git/.gitconfig` の `[include]` が読み込む

## トラブルシューティング

### Claude Code / Antigravity が壊れた

```bash
# コンテナ内で実行。実物を消せば次回起動時に bootstrap が再インストールする
rm -rf ~/.local/bin/claude ~/.local/share/claude
exit
```

```powershell
docker restart devenv
```

### Neovim プラグインが壊れた

```bash
rm -rf ~/.local/share/nvim ~/.local/state/nvim ~/.cache/nvim
```

の後、`docker restart devenv` で再 bootstrap される。

### 初回インストールがまた走った / 状態が消えた

`devenv_home` volume が消えていないか確認する:

```powershell
docker volume ls | Select-String devenv_home
```

`down -v` や volume 削除を行うと全状態が消える。このホストには他プロジェクト（Dify 等）の volume も同居しているため、**`docker volume prune` は使わないこと**。

### git commit で「Please tell me who you are」と言われる

`docker/.env` に `GIT_USER_NAME` / `GIT_USER_EMAIL` を設定し、`docker restart devenv`。

### クリップボードが Windows に連携されない

Windows Terminal（v1.18+）の Settings > Actions で「Allow OSC 52 clipboard access」を有効化する。

### Docker socket にアクセスできない

Rancher Desktop の「WSL Integration」が有効か確認。コンテナ内で `docker ps` が動けば OK（注: 現状イメージに docker CLI は未導入。将来課題）。

### ディスクが逼迫した

```powershell
.\scripts\disk-management.ps1
```
