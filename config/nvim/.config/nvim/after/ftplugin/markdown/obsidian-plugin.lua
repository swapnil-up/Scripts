-- Add the Obsidian plugin for note-taking
local obsidian_plugin = {
  'epwalsh/obsidian.nvim',
  -- If you want to disable type checking, comment the next line
  -- event = { "BufReadPre " .. vim.fn.expand('~') .. "/github/obsidian-vault/**.md" },
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-telescope/telescope.nvim",
    "nvim-treesitter/nvim-treesitter",
  },
  config = function()
    require("obsidian").setup({
      workspaces = {
        {
          name = "vault",
          path = "~/github/obsidian-vault",
        },
      },
      notes_subdir = "daily n gratitude",
      templates = {
        subdir = "templates",
      },
      mappings = {
        -- Overrides the "gf" mapping to work on markdown files only
        open_link = { "gd", "gx" },
        -- Create a new note from a template
        new = "<leader>on",
        -- Yank the current note's title to register 0
        yank_note_title = "y<C-y>",
        -- Toggle check-boxes
        toggle_check = { "<C-space>", "<leader>ch" },
      },
      -- Use the 'gf' mapping to also follow links in other filetypes
      follow_url_func = function(url)
        if url:match("http") then
          -- Open in browser
          vim.fn.jobstart({"xdg-open", url})
        else
          -- Try to find the file in the vault
          local path = require("obsidian").util.find_note(url)
          if path then
            vim.cmd(string.format("edit %s", path))
          end
        end
      end,
      -- Use the default preview function
      note_id = function()
        return require("obsidian.util").format_time("%Y-%m-%d")
      end,
      -- Use the default note id function
      note_id_func = function()
        return require("obsidian.util").format_time("%Y-%m-%d")
      end,
      -- Use the default note title function
      note_title_func = function()
        return require("obsidian.util").format_time("%Y-%m-%d")
      end,
    })
  end,
}