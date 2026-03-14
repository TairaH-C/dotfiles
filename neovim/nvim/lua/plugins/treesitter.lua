return {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  event = { "BufReadPost", "BufNewFile" },
  config = function()
    require("nvim-treesitter.configs").setup({
      ensure_installed = {
        "python", "lua", "vim", "vimdoc",
        "json", "yaml", "toml", "bash", "markdown",
      },
      highlight = { enable = true },
      indent = { enable = true },
    })
  end,
}
