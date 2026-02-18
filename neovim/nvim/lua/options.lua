local opt = vim.opt

-- Line numbers
opt.number = true
opt.relativenumber = true

-- Indentation
opt.tabstop = 2
opt.shiftwidth = 2
opt.expandtab = true
opt.smartindent = true

-- Search
opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = false
opt.incsearch = true

-- Appearance
opt.termguicolors = true
opt.signcolumn = "yes"
opt.cursorline = true
opt.scrolloff = 8

-- Behavior
opt.splitbelow = true
opt.splitright = true
opt.undofile = true
opt.updatetime = 250
opt.timeoutlen = 300
opt.clipboard = "unnamedplus"
opt.mouse = "a"

-- File encoding
opt.encoding = "utf-8"
opt.fileencoding = "utf-8"
