return {
  -- Treesitter
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      require("nvim-treesitter").setup({
        ensure_installed = {
          "python",
          "lua",
          "vim",
          "vimdoc",
          "json",
          "yaml",
          "toml",
          "bash",
          "markdown",
          "markdown_inline",
          "typescript",
          "tsx",
          "javascript",
          "html",
          "css",
          "dockerfile",
          "gitcommit",
          "diff",
          "regex",
          "query",
        },
      })
    end,
  },

  -- Treesitter textobjects
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    branch = "main",
    event = { "BufReadPost", "BufNewFile" },
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    config = function()
      require("nvim-treesitter-textobjects").setup({
        select = {
          lookahead = true,
        },
        move = {
          set_jumps = true,
        },
      })

      local select = require("nvim-treesitter-textobjects.select")
      local move = require("nvim-treesitter-textobjects.move")
      local swap = require("nvim-treesitter-textobjects.swap")

      -- Select textobjects
      local select_maps = {
        ["af"] = "@function.outer",
        ["if"] = "@function.inner",
        ["ac"] = "@class.outer",
        ["ic"] = "@class.inner",
        ["aa"] = "@parameter.outer",
        ["ia"] = "@parameter.inner",
      }
      for key, query in pairs(select_maps) do
        vim.keymap.set({ "x", "o" }, key, function()
          select.select_textobject(query, "textobjects")
        end, { desc = "Select " .. query })
      end

      -- Move: goto next start
      local next_start_maps = {
        ["]f"] = "@function.outer",
        ["]c"] = "@class.outer",
        ["]a"] = "@parameter.inner",
      }
      for key, query in pairs(next_start_maps) do
        vim.keymap.set({ "n", "x", "o" }, key, function()
          move.goto_next_start(query, "textobjects")
        end, { desc = "Next " .. query .. " start" })
      end

      -- Move: goto next end
      local next_end_maps = {
        ["]F"] = "@function.outer",
        ["]C"] = "@class.outer",
      }
      for key, query in pairs(next_end_maps) do
        vim.keymap.set({ "n", "x", "o" }, key, function()
          move.goto_next_end(query, "textobjects")
        end, { desc = "Next " .. query .. " end" })
      end

      -- Move: goto prev start
      local prev_start_maps = {
        ["[f"] = "@function.outer",
        ["[c"] = "@class.outer",
        ["[a"] = "@parameter.inner",
      }
      for key, query in pairs(prev_start_maps) do
        vim.keymap.set({ "n", "x", "o" }, key, function()
          move.goto_previous_start(query, "textobjects")
        end, { desc = "Prev " .. query .. " start" })
      end

      -- Move: goto prev end
      local prev_end_maps = {
        ["[F"] = "@function.outer",
        ["[C"] = "@class.outer",
      }
      for key, query in pairs(prev_end_maps) do
        vim.keymap.set({ "n", "x", "o" }, key, function()
          move.goto_previous_end(query, "textobjects")
        end, { desc = "Prev " .. query .. " end" })
      end

      -- Swap
      vim.keymap.set("n", "<leader>a", function()
        swap.swap_next("@parameter.inner")
      end, { desc = "Swap next parameter" })
      vim.keymap.set("n", "<leader>A", function()
        swap.swap_previous("@parameter.inner")
      end, { desc = "Swap prev parameter" })
    end,
  },

}
