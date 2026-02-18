return {
  "akinsho/toggleterm.nvim",
  version = "*",
  keys = {
    { "<C-\\>", "<cmd>ToggleTerm<cr>", desc = "Toggle terminal" },
    { "<leader>cc", "<cmd>ToggleTerm direction=float<cr>", desc = "Claude Code terminal" },
  },
  config = function()
    require("toggleterm").setup({
      size = function(term)
        if term.direction == "horizontal" then
          return 15
        elseif term.direction == "vertical" then
          return vim.o.columns * 0.4
        end
      end,
      open_mapping = [[<C-\>]],
      direction = "horizontal",
      shade_terminals = true,
      float_opts = {
        border = "curved",
        width = function() return math.floor(vim.o.columns * 0.8) end,
        height = function() return math.floor(vim.o.lines * 0.8) end,
      },
    })
  end,
}
