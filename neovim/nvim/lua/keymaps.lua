vim.g.mapleader = " "
vim.g.maplocalleader = " "

local map = vim.keymap.set

-- Window navigation
map("n", "<C-h>", "<C-w>h", { desc = "Move to left window" })
map("n", "<C-j>", "<C-w>j", { desc = "Move to lower window" })
map("n", "<C-k>", "<C-w>k", { desc = "Move to upper window" })
map("n", "<C-l>", "<C-w>l", { desc = "Move to right window" })

-- Buffer navigation
map("n", "<S-h>", ":bprevious<CR>", { desc = "Previous buffer", silent = true })
map("n", "<S-l>", ":bnext<CR>", { desc = "Next buffer", silent = true })

-- Move lines
map("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move selection down", silent = true })
map("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move selection up", silent = true })

-- Stay centered
map("n", "<C-d>", "<C-d>zz")
map("n", "<C-u>", "<C-u>zz")
map("n", "n", "nzzzv")
map("n", "N", "Nzzzv")

-- Escape
map("i", "jk", "<Esc>")

-- Save
map("n", "<leader>w", ":w<CR>", { desc = "Save", silent = true })

-- Clear search
map("n", "<Esc>", ":noh<CR>", { desc = "Clear search highlight", silent = true })
