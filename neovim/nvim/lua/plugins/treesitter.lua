return {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  event = { "BufReadPost", "BufNewFile" },
  config = function()
    require("nvim-treesitter.configs").setup({
      ensure_installed = {
        "lua", "python", "go", "rust", "typescript", "javascript",
        "php", "json", "yaml", "toml", "bash", "markdown", "vim", "vimdoc",
      },
      highlight = { enable = true },
      indent = { enable = true },
    })
  end,
}
