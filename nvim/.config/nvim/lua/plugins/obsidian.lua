return {
  "epwalsh/obsidian.nvim",
  version = "*",
  ft = "markdown",
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  opts = {
    workspaces = {
      {
        name = "personal",
        path = "~/obsidian-vault", -- change to your actual vault path
      },
    },
    daily_notes = {
      folder = "Daily",
    },
    completion = {
      nvim_cmp = true, -- plays nicely with LazyVim
    },
    ui = {
      enable = true, -- checkbox / bullets UI
    },
  },
}
