# dotfiles

Docker 上で完結する Neovim + tmux + zsh 開発環境。Catppuccin Mocha で統一されたモダン CLI 構成。

## 構成

```text
dotfiles/
├── docker/
│   ├── Dockerfile            # Ubuntu 24.04 ベースの開発イメージ
│   ├── docker-compose.yml    # volume 永続化・API key 注入
│   ├── entrypoint.sh         # 初回 bootstrap (Nvim/tmux プラグイン)
│   └── persist/              # zsh_history, .gitconfig.local
├── install.sh                # メインインストーラ
├── scripts/
│   └── setup-symlinks.sh     # シンボリックリンク作成
├── git/
│   └── .gitconfig            # delta 統合・Catppuccin テーマ
├── shell/
│   ├── .zshrc                # zinit + zoxide + fzf (Catppuccin)
│   ├── .aliases              # eza / bat / rg / fd エイリアス
│   └── starship.toml         # プロンプト設定
├── neovim/
│   └── nvim/
│       ├── init.lua           # 4 行の require のみ
│       └── lua/
│           ├── config/
│           │   ├── options.lua    # エディタオプション
│           │   ├── keymaps.lua    # Vim 標準準拠キーマップ
│           │   ├── autocmds.lua   # ヤンクハイライト・カーソル復帰等
│           │   └── lazy.lua       # lazy.nvim ブートストラップ
│           └── plugins/
│               ├── colorscheme.lua # Catppuccin Mocha
│               ├── ui.lua         # lualine, bufferline, noice, alpha, ibl
│               ├── editor.lua     # flash, mini.*, todo-comments, persistence
│               ├── coding.lua     # blink.cmp + copilot
│               ├── lsp.lua        # 10 言語 LSP + conform + nvim-lint
│               ├── treesitter.lua # 22 言語 + textobjects
│               ├── telescope.lua  # fzf-native 拡張
│               ├── git.lua        # gitsigns + lazygit
│               ├── debug.lua      # nvim-dap + dap-ui
│               └── util.lua       # which-key, trouble
├── tmux/
│   └── .tmux.conf             # C-Space prefix, vim 連携, Catppuccin
└── lazygit/
    └── config.yml             # Catppuccin + delta pager
```

## Windows 初期セットアップ

新しい Windows 11 マシンで開発環境を構築する手順。`scripts/windows-setup.ps1` が
winget 経由で主要ツールを自動インストールする。

**実行モデル**: 通常 (非管理者) PowerShell から起動する。スクリプトは内部で

1. 管理者権限が必要なパッケージを **優先して** バッチ処理 (1 回の UAC で全部入る)
2. その後ユーザースコープのパッケージを順次インストール

の順で動く。winget は管理者シェルだと PATH に乗らない / 実行できないことがあるため、
ユーザーセッションで解決した `winget.exe` のフルパスを昇格された子プロセスに渡す。
そのため「管理者 PowerShell には winget がない」という症状を回避できる。

### 1. 前提: winget

Windows 11 には標準で winget (App Installer) が同梱されている。古い場合は
Microsoft Store から "App Installer" を更新する。

### 2. スクリプト実行

**通常の (管理者ではない) PowerShell** を開き:

```powershell
# リポジトリルートで実行
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\windows-setup.ps1
```

実行直後に UAC ダイアログが出るので承認する。新しい昇格 PowerShell ウィンドウが開き、
管理者必須パッケージ (Office / Rancher Desktop / Azure CLI / Functions Core Tools / SSMS)
を順番にインストールする。終わったら任意のキーで閉じると、元のウィンドウでユーザー
スコープのインストールが続行する。

オプション:

```powershell
# UAC を出さず、管理者必須パッケージは全てスキップ
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\windows-setup.ps1 -SkipAdminPackages

# 何がインストールされるかだけ確認 (UAC は出るが winget は走らない)
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\windows-setup.ps1 -DryRun

# 既にインストール済みでも再インストールを試みる
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\windows-setup.ps1 -Force
```

### 3. インストール対象

優先度順 (管理者必須が先):

| 優先度 | ソフトウェア | winget ID | スコープ | 備考 |
|:------:|-------------|-----------|----------|------|
| ★ | Microsoft 365 (Office) | `Microsoft.Office` | machine | 要管理者 |
| ★ | Rancher Desktop | `SUSE.RancherDesktop` | machine | 要管理者 (WSL 統合・サービス登録) |
| ★ | Azure CLI | `Microsoft.AzureCLI` | machine | MSI のため要管理者 |
| ★ | Azure Functions Core Tools | `Microsoft.Azure.FunctionsCoreTools` | machine | MSI のため要管理者 |
| ★ | SQL Server Management Studio | `Microsoft.SQLServerManagementStudio` | machine | 要管理者 |
|   | Microsoft PowerToys | `Microsoft.PowerToys` | user | |
|   | Visual Studio Code | `Microsoft.VisualStudioCode` | user | User Installer |
|   | Azure Storage Explorer | `Microsoft.Azure.StorageExplorer` | user | |
|   | uv | `astral-sh.uv` | user | Python パッケージマネージャ |
|   | Git | `Git.Git` | user | |
|   | Node.js LTS | `OpenJS.NodeJS.LTS` | user | |
|   | Go | `GoLang.Go` | user | |
|   | Zoom | `Zoom.Zoom` | user | |

### 4. 手動セットアップが必要な項目

自動化できない or 後続の手動操作が必要なもの:

#### WSL2 の有効化

管理者 PowerShell で:

```powershell
wsl --install
```

実行後 Windows を再起動。既定で Ubuntu がインストールされる。別ディストリを使うなら
`wsl --install -d <Distro>`。

#### Rancher Desktop の初期設定

1. 初回起動時に "Container Engine" で **dockerd (moby)** を選択
2. "WSL Integration" で使用する WSL ディストリを有効化
3. 必要に応じて CPU / メモリ / ディスクサイズを調整

#### Microsoft 365 のライセンス認証

インストール完了後、任意の Office アプリを起動して組織アカウントでサインイン。

#### Git のユーザ情報

```powershell
git config --global user.name  "Your Name"
git config --global user.email "you@example.com"
```

#### PowerToys の推奨設定

初回起動後に FancyZones / PowerToys Run / Keyboard Manager を有効化。設定内容は
各自の好みで調整する。

---

## WSL セットアップ (開発環境本体)

### 前提条件

- Windows 11 + Rancher Desktop (WSL2 バックエンド)
- Docker Compose が使えること
- Windows Terminal 1.18 以上 (OSC 52 クリップボード対応)

### 1. リポジトリをクローン

```bash
git clone https://github.com/TairaH-C/dotfiles.git
cd dotfiles
```

### 2. Git のメールアドレスを設定

`docker/persist/.gitconfig.local` にメールアドレスを記入する。このファイルはコンテナ内にマウントされる。

```ini
[user]
    email = your@email.com
```

### 3. API キーを設定

`docker/.env` を作成する。このファイルは `.gitignore` 済み。

```bash
ANTHROPIC_API_KEY=sk-ant-...
OPENAI_API_KEY=sk-...        # 任意
GITHUB_TOKEN=ghp_...          # 任意
```

### 4. ビルド

```bash
docker compose -f docker/docker-compose.yml build
```

初回ビルドは全パッケージをインストールするため時間がかかる。2 回目以降はキャッシュが効く。

### 5. 起動

```bash
docker compose -f docker/docker-compose.yml run --rm dev
```

初回起動時に entrypoint が自動で以下を実行する:

- Neovim プラグインの headless sync (`Lazy! sync`)
- tmux プラグインのインストール (TPM)

2 回目以降はスキップされる (named volume にマーカーファイルを保存)。

### 6. tmux を開始

コンテナ内で:

```bash
tmux new-session -A -s main
```

`-A` は既存セッションがあればアタッチ、なければ新規作成する。

### 7. 再接続

別ターミナルから実行中のコンテナに入る:

```bash
docker exec -it devenv tmux attach -t main
```

## 日常のワークフロー

```bash
# 開発セッション開始
docker compose -f docker/docker-compose.yml run --rm dev
tmux new-session -A -s main

# tmux 内で Neovim を起動
nvim .

# 別ペインで Claude Code を使う
# tmux prefix (C-Space) + | で縦分割、claude コマンドを実行

# 再接続 (別ターミナルから)
docker exec -it devenv tmux attach -t main

# dotfiles 変更後のリビルド (volume は保持される)
docker compose -f docker/docker-compose.yml build
docker compose -f docker/docker-compose.yml run --rm dev
```

## tmux

プレフィックスキーは `C-Space`。

### 基本操作

| キー | 動作 |
|------|------|
| `C-Space \|` | 縦分割 (カレントパス) |
| `C-Space -` | 横分割 (カレントパス) |
| `C-Space c` | 新しいウィンドウ |
| `C-h/j/k/l` | ペイン移動 (Neovim 分割とシームレス連携) |
| `C-Space H/J/K/L` | ペインリサイズ |
| `C-Space r` | 設定リロード |

### レイアウト

| キー | 動作 |
|------|------|
| `C-Space D` | 開発レイアウト: Neovim (左 65%) + Claude Code (右上) + ターミナル (右下) |
| `C-Space A` | エージェントレイアウト: 3 ペイン均等分割 |

### コピーモード

vi キーバインド。`v` で選択開始、`y` でコピー。OSC 52 経由で Windows クリップボードに自動連携。

### セッション永続化

tmux-resurrect + tmux-continuum により、15 分ごとにセッションが自動保存される。コンテナ再起動後も `tmux-plugins` volume にデータが残る。

## Neovim

### キーマップ一覧

リーダーキーは `Space`。`Space` を押して待つと which-key が全コマンドを表示する。

#### ファイル操作

| キー | 動作 | VS Code 相当 |
|------|------|-------------|
| `<leader><space>` | ファイル検索 | `Ctrl+P` |
| `<leader>sg` | テキスト検索 (grep) | `Ctrl+Shift+F` |
| `<leader>sk` | キーマップ検索 | `Ctrl+Shift+P` |
| `<leader>e` | ファイルエクスプローラ (カレントファイル) | サイドバー |
| `<leader>E` | ファイルエクスプローラ (cwd) | サイドバー |
| `<leader>fr` | 最近開いたファイル | |
| `<leader>fb` | バッファ一覧 | |

#### LSP

| キー | 動作 |
|------|------|
| `gd` | 定義へジャンプ |
| `gr` | 参照一覧 |
| `gI` | 実装へジャンプ |
| `gy` | 型定義へジャンプ |
| `K` | ホバードキュメント |
| `gK` | シグネチャヘルプ |
| `<leader>cr` | リネーム |
| `<leader>ca` | コードアクション |
| `<leader>cf` | フォーマット |
| `<leader>cd` | 行の診断 |

#### Git

| キー | 動作 |
|------|------|
| `<leader>gg` | LazyGit 起動 |
| `]h` / `[h` | 次/前のハンク |
| `<leader>ghs` | ハンクをステージ |
| `<leader>ghr` | ハンクをリセット |
| `<leader>ghb` | blame 表示 |
| `<leader>ghd` | diff 表示 |

#### デバッグ

| キー | 動作 | VS Code 相当 |
|------|------|-------------|
| `<leader>db` | ブレークポイント設定/解除 | `F9` |
| `<leader>dc` | 続行 | `F5` |
| `<leader>di` | ステップイン | `F11` |
| `<leader>do` | ステップオーバー | `F10` |
| `<leader>dO` | ステップアウト | `Shift+F11` |
| `<leader>du` | DAP UI 表示切替 | |
| `<leader>dt` | 終了 | `Shift+F5` |

#### エディタ

| キー | 動作 |
|------|------|
| `s` | Flash ジャンプ |
| `S` | Flash Treesitter |
| `gsa` | surround 追加 |
| `gsd` | surround 削除 |
| `gsr` | surround 置換 |
| `<leader>bd` | バッファ削除 |
| `<leader>xx` | 診断一覧 (Trouble) |
| `<leader>cc` | Claude Code ターミナル |

#### セッション

| キー | 動作 |
|------|------|
| `<leader>qs` | セッション復元 |
| `<leader>ql` | 最後のセッション復元 |
| `<leader>qq` | 全て終了 |

#### ナビゲーション

| キー | 動作 |
|------|------|
| `C-h/j/k/l` | ウィンドウ/ペイン移動 (tmux 連携) |
| `S-h` / `S-l` | 前/次のバッファ |
| `[d` / `]d` | 前/次の diagnostic |
| `[f` / `]f` | 前/次の関数 |
| `[c` / `]c` | 前/次のクラス |
| `[t` / `]t` | 前/次の TODO コメント |

### LSP 対応言語

| 言語 | LSP サーバー | フォーマッタ |
|------|-------------|-------------|
| Python | basedpyright + ruff | ruff_format |
| TypeScript/JavaScript | ts_ls | prettierd |
| Rust | rust_analyzer | rustfmt |
| Go | gopls | gofumpt |
| Lua | lua_ls | stylua |
| JSON | jsonls | prettierd |
| YAML | yamlls | prettierd |
| Bash | bashls | shfmt |
| TOML | taplo | taplo |

フォーマットはファイル保存時に自動実行される (`conform.nvim`)。

### Copilot

GitHub Copilot を使用する場合は、コンテナ内で `:Copilot auth` を実行して認証する。認証情報は `claude-state` volume に保存される。

## シェル (Zsh)

### プラグイン (zinit)

- zsh-autosuggestions: コマンド候補のサジェスト
- zsh-syntax-highlighting: 入力中のシンタックスハイライト
- zsh-completions: 追加の補完定義

### エイリアス

| エイリアス | コマンド |
|-----------|---------|
| `ls` | `eza --icons` |
| `ll` | `eza -lah --icons --git` |
| `lt` | `eza --tree --icons --level=2` |
| `cd` | `z` (zoxide) |
| `cat` | `bat --paging=never` |
| `grep` | `rg` (ripgrep) |
| `find` | `fd` |
| `vi` / `vim` | `nvim` |
| `lg` | `lazygit` |
| `gs` / `gd` / `gl` | git status / diff / log |

## Git

- **pager**: delta (side-by-side diff, 行番号表示, Catppuccin テーマ)
- **pull**: rebase モード
- **push**: `autoSetupRemote = true`
- **merge**: diff3 コンフリクトスタイル
- **個人設定**: `~/.gitconfig.local` で email 等を管理 (コミットしない)

## Docker 永続化データ

| Volume | パス | 内容 |
|--------|------|------|
| `nvim-data` | `~/.local/share/nvim` | lazy.nvim プラグイン + Mason LSP サーバー |
| `nvim-state` | `~/.local/state/nvim` | undo 履歴, shada |
| `nvim-cache` | `~/.cache/nvim` | treesitter パーサー, lazy キャッシュ |
| `tmux-plugins` | `~/.tmux/plugins` | TPM プラグイン |
| `zsh-plugins` | `~/.local/share/zinit` | zinit プラグインキャッシュ |
| `zoxide-db` | `~/.local/share/zoxide` | zoxide 頻度データベース |
| `cargo` | `~/.cargo` | Rust ツールチェーン |
| `go-pkg` | `~/go` | Go パッケージ |
| `claude-state` | `~/.claude` | Claude Code 認証・設定 |

`docker compose build` でイメージを再ビルドしても、これらの volume は保持される。

### volume の完全リセット

```bash
docker compose -f docker/docker-compose.yml down -v
```

## トラブルシューティング

### Neovim プラグインが壊れた

```bash
# コンテナ内で実行
rm -rf ~/.local/share/nvim ~/.local/state/nvim ~/.cache/nvim
# 再起動すると entrypoint が再 bootstrap する
```

### tmux プラグインが読み込まれない

```bash
# コンテナ内で実行
~/.tmux/plugins/tpm/bin/install_plugins
# または tmux 内で C-Space I
```

### クリップボードが Windows に連携されない

Windows Terminal が OSC 52 に対応している必要がある (v1.18 以上)。Settings > Actions で「Allow OSC 52 clipboard access」が有効になっているか確認する。

### Mason の LSP サーバーがインストールされない

```vim
:Mason
```

で Mason UI を開き、手動でインストールできる。初回は `:MasonUpdate` を実行する。

### Docker socket にアクセスできない

Rancher Desktop の設定で「WSL Integration」が有効になっているか確認する。コンテナ内で `docker ps` が動作すれば OK。
