# 技術スタック (TECH-STACK.md)

この Neovim 開発環境で使用されている主要なツールとライブラリの一覧です。

## 1. システム環境 (System)

| ツール             | バージョン         | 説明                          |
| :----------------- | :----------------- | :---------------------------- |
| **OS**             | Ubuntu 24.04 (LTS) | コンテナのベースイメージ      |
| **Runtime**        | Docker             | コンテナ化による環境の一貫性  |
| **Virtualization** | WSL2               | Windows 上での Linux 実行環境 |
| **Network**        | Rancher Desktop    | Docker Desktop の代替 (OSS)   |

---

## 2. シェル・端末ツール (Shell & CLI)

| カテゴリ         | ツール       | バージョン | 説明                               |
| :--------------- | :----------- | :--------- | :--------------------------------- |
| **Shell**        | zsh          | 5.9        | 高機能な対話型シェル               |
| **Shell Plugin** | zinit        | -          | シェルプラグインマネージャー       |
| **Multiplexer**  | tmux         | 3.4        | 端末の画面分割・セッション保持     |
| **Navigation**   | zoxide       | 0.9.9      | ディレクトリ間の高速移動 (z)       |
| **Finder**       | fzf          | 0.60.3     | 曖昧検索 (Fuzzy Finder)            |
| **Prompt**       | starship     | 1.24.2     | 高速でカスタマイズ可能なプロンプト |
| **Lister**       | eza          | 0.23.4     | アイコン付きの `ls` 代替           |
| **Searcher**     | ripgrep (rg) | 14.1.0     | 高速な文字列検索ツール             |
| **Finder**       | fd-find (fd) | 9.0.0      | 高速なファイル検索ツール           |
| **Viewer**       | bat          | 0.24.0     | シンタックスハイライト付き `cat`   |
| **Git Diff**     | delta        | 0.19.2     | 見やすい `git diff` 表示           |
| **Git TUI**      | lazygit      | 0.46.1     | 端末上の Git 操作インターフェース  |

---

## 3. 開発言語・ランタイム (Runtimes)

| ツール      | バージョン      | 説明                                   |
| :---------- | :-------------- | :------------------------------------- |
| **Python**  | 3.x (uv 管理)   | 高速な Python パッケージマネージャー   |
| **uv**      | 0.6.9           | Rust 製の超高速 Python パッケージ管理  |
| **Node.js** | 22.22.2 (LTS)   | JavaScript ランタイム (LSP 動作に必要) |
| **C/C++**   | build-essential | コンパイル環境 (Treesitter 用)         |

---

## 4. エディタ (Editor)

| ツール         | バージョン | 説明                                  |
| :------------- | :--------- | :------------------------------------ |
| **Neovim**     | v0.11.6    | コアエディタ (Nightly 相当の最新機能) |
| **Lazy.nvim**  | -          | 高速なプラグインマネージャー          |
| **Mason.nvim** | -          | LSP, Formatter, Linter の管理         |

---

## 5. AI 開発支援 (AI Tools)

| ツール               | バージョン | 説明                               |
| :------------------- | :--------- | :--------------------------------- |
| **Claude Code**      | 2.1.91     | Anthropic 製の CLI AI アシスタント |
| **OpenCode**         | 1.3.13     | オープンソースの AI 開発ツール     |
| **oh-my-openagents** | 3.14.0     | AI エージェント連携ライブラリ      |

---

## 6. 主要な Neovim プラグイン

この環境には 47 以上のプラグインが導入されています。主要なものは以下の通りです：

- **UI**: `catppuccin` (テーマ), `lualine` (ステータスライン), `bufferline` (タブ)
- **Editor**: `telescope` (検索), `flash` (高速移動), `mini.files` (エクスプローラー)
- **Coding**: `blink.cmp` (補完), `conform` (フォーマッタ), `nvim-lint` (リンター)
- **LSP**: `nvim-lspconfig` (LSP 設定), `basedpyright` (Python), `ruff` (Python)
- **Git**: `gitsigns` (変更箇所の表示), `lazygit.nvim` (連携)
- **Others**: `nvim-dap` (デバッグ), `toggleterm` (端末連携), `persistence` (セッション保持)

---

## 7. 公式ドキュメントへのリンク

- [Neovim Documentation](https://neovim.io/doc/)
- [Lazy.nvim](https://github.com/folke/lazy.nvim)
- [Telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)
- [Mason.nvim](https://github.com/williamboman/mason.nvim)
- [Lazygit](https://github.com/jesseduffield/lazygit)
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code)
