-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
vim.keymap.set("n", "<leader>oo", ":ObsidianOpen<CR>")
vim.keymap.set("n", "<leader>of", ":ObsidianFollowLink<CR>")
vim.keymap.set("n", "<leader>od", ":ObsidianDailies<CR>")
vim.keymap.set("n", "<leader>on", ":ObsidianNew<CR>")
vim.keymap.set("n", "<leader>os", ":ObsidianSearch ")
vim.keymap.set("n", "<leader>oq", ":ObsidianQuickSwitch<CR>")
