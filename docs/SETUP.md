# セットアップガイド (SETUP.md)

このドキュメントでは、Windows 11 上で Rancher Desktop と WSL2 を使用して、Neovim 開発環境を構築する手順を説明します。

## 1. 前提条件

セットアップを開始する前に、以下の環境が整っていることを確認してください。

- **OS**: Windows 11 (22H2 以降推奨)
- **WSL2**: Ubuntu 22.04 または 24.04 がインストール済みであること
- **Rancher Desktop**: インストール済みで、`dockerd` (moby) が選択されていること
- **Git for Windows**: Windows 側でリポジトリを操作するために必要

## 2. 初回セットアップ手順 (9ステップ)

以下の手順に従って環境を構築します。

### Step 1: リポジトリのクローン
WSL2 または Windows のターミナルを開き、リポジトリをクローンします。
```bash
git clone https://github.com/your-repo/dotfiles.git ~/dotfiles
cd ~/dotfiles
```

### Step 2: .wslconfig の設定
WSL2 のパフォーマンスとネットワーク設定を最適化します。テンプレートをユーザーディレクトリにコピーしてください。
```powershell
# Windows PowerShell で実行
cp dotfiles/.wslconfig.template $HOME/.wslconfig
```
※ すでに `.wslconfig` が存在する場合は、必要に応じて内容をマージしてください。

### Step 3: Docker イメージのビルド
開発コンテナのイメージをビルドします。
```bash
cd dotfiles/docker
docker compose build
```

### Step 4: コンテナの起動
バックグラウンドでコンテナを起動します。
```bash
docker compose up -d
```

### Step 5: 初回起動の待機
コンテナの初回起動時には、Neovim プラグインの同期や Treesitter のコンパイルが行われます。
**30秒から2分程度** 待機してから次のステップに進んでください。

### Step 6: コンテナへのアクセス確認
コンテナ内に入り、シェル (zsh) が正常に動作することを確認します。
```bash
docker exec -it devenv zsh
```

### Step 7: tmux の起動確認
コンテナ内で `tmux` を実行し、ステータスラインやペイン操作ができることを確認します。

### Step 8: Neovim の起動確認
`nvim` を起動し、プラグインのエラーが出ていないか確認します。
`:checkhealth` を実行して、主要なプロバイダーが正常であることを確認してください。

### Step 9: AI ツールの認証
この環境には AI 開発支援ツールがプリインストールされています。以下のコマンドでログインを行ってください。
- **Claude Code**: `claude auth login`
- **OpenCode**: 必要な設定ファイル（`.opencode.json` 等）を配置

---

## 3. 日常のワークフロー

### コンテナの管理
- **起動**: `docker compose up -d`
- **停止**: `docker compose stop`
- **削除**: `docker compose down` (ボリュームは保持されます)

### プロジェクトへのアクセス
ホスト側の `workspace` ディレクトリは、コンテナ内の `/home/dev/workspace` にマウントされます。
すべての開発作業はこのディレクトリ内で行ってください。

### よく使うコマンド
- `z`: 過去に訪れたディレクトリに高速移動 (zoxide)
- `lg`: Git UI を起動 (lazygit)
- `ff`: ファイル検索 (Telescope find_files)

---

## 4. トラブルシューティング

### クリップボードが動かない
OSC52 を使用してホストとクリップボードを共有しています。
- tmux を使用している場合、`tmux.conf` に OSC52 設定が含まれているか確認してください。
- ターミナル（Windows Terminal など）が OSC52 をサポートしている必要があります。

### LSP が起動しない
初回起動時に `mason.nvim` が必要なバイナリを自動インストールします。
- インターネット接続を確認してください。
- `:Mason` コマンドでインストール状況を確認し、失敗している場合は手動で `i` キーを押して再試行してください。

### ディスク容量不足
WSL2 の仮想ディスク (`.vhdx`) は自動で縮小されません。
付属のスクリプトを使用して、不要なデータを削除し、ディスクを最適化してください。
```powershell
# Windows PowerShell (管理者) で実行
.\scripts\disk-management.ps1
```

---

## 5. ディスク管理について

`scripts/disk-management.ps1` は以下の操作を一括で行います：
1. Docker の未使用イメージ、コンテナ、ビルドキャッシュの削除
2. WSL2 仮想ディスクの実サイズの確認
3. 仮想ディスクの最適化・圧縮 (要 `wsl --shutdown`)

定期的に実行することで、ホストマシンのストレージを節約できます。
