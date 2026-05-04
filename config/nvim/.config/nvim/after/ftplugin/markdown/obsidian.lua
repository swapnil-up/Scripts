-- Obsidian-style note-taking configuration for Markdown files
-- This provides key mappings and functions for Obsidian-like functionality

local obsidian = {}

-- Function to create a new note with a timestamp
function obsidian.create_note()
  local note_name = vim.fn.input("Note name: ")
  if note_name == "" then
    return
  end
  
  -- Create a filename-friendly version
  local filename = note_name:gsub("[^%w%s%-]", ""):gsub("%s+", "-"):lower()
  local full_path = vim.fn.getcwd() .. "/" .. filename .. ".md"
  
  -- Create the file if it doesn't exist
  if vim.fn.filereadable(full_path) == 0 then
    -- Create the note with a title
    local lines = {
      "# " .. note_name,
      "",
      "Created: " .. os.date("%Y-%m-%d %H:%M:%S"),
      ""
    }
    vim.fn.writefile(lines, full_path)
  end
  
  -- Open the file
  vim.cmd("edit " .. full_path)
end

-- Function to insert a wiki link
function obsidian.insert_link()
  local link_text = vim.fn.input("Link text: ")
  if link_text == "" then
    return
  end
  
  -- Find the file (simplified - in practice you might want to search)
  local link = "[[" .. link_text .. "]]"
  local pos = vim.api.nvim_win_get_cursor(0)
  vim.api.nvim_put({link}, "", true, true)
end

-- Function to find and open a note
function obsidian.find_note()
  local note_name = vim.fn.input("Find note: ")
  if note_name == "" then
    return
  end
  
  -- Simplified search - in practice you might want to use telescope or similar
  vim.cmd("Telescope find_files cwd=" .. vim.fn.getcwd() .. " prompt_title='Find Note'")
end

-- Function to insert a daily note link
function obsidian.insert_daily_note()
  local date = os.date("%Y-%m-%d")
  local daily_note = "daily n gratitude/" .. date .. ".md"
  local link = "[[" .. date .. "]]"
  
  -- Create daily note if it doesn't exist
  local full_path = vim.fn.getcwd() .. "/" .. daily_note
  if vim.fn.filereadable(full_path) == 0 then
    local lines = {
      "# " .. date,
      "",
      "Daily Note - " .. date,
      ""
    }
    vim.fn.writefile(lines, full_path)
  end
  
  -- Insert the link
  local pos = vim.api.nvim_win_get_cursor(0)
  vim.api.nvim_put({link}, "", true, true)
end

-- Set up key mappings for Obsidian-like functionality
vim.api.nvim_buf_set_keymap(0, "n", "<leader>on", ":lua require('obsidian').create_note()<CR>", { noremap = true, silent = true, desc = "Create new note" })
vim.api.nvim_buf_set_keymap(0, "n", "<leader>ol", ":lua require('obsidian').insert_link()<CR>", { noremap = true, silent = true, desc = "Insert link" })
vim.api.nvim_buf_set_keymap(0, "n", "<leader>of", ":lua require('obsidian').find_note()<CR>", { noremap = true, silent = true, desc = "Find note" })
vim.api.nvim_buf_set_keymap(0, "n", "<leader>od", ":lua require('obsidian').insert_daily_note()<CR>", { noremap = true, silent = true, desc = "Insert daily note" })

-- Return the module
return obsidian