-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- GitHub Copilot keymaps
local map = vim.keymap.set

-- Copilot suggestions (already configured in plugin, but documented here)
-- Alt+l: Accept suggestion
-- Alt+w: Accept word
-- Alt+j: Accept line
-- Alt+]: Next suggestion
-- Alt+[: Previous suggestion
-- Ctrl+]: Dismiss suggestion
-- Alt+Enter: Open Copilot panel

-- Copilot Chat keymaps
map("n", "<leader>cc", "<cmd>CopilotChat<CR>", { desc = "CopilotChat - Open chat" })
map("v", "<leader>cc", "<cmd>CopilotChatExplain<CR>", { desc = "CopilotChat - Explain selection" })
map("v", "<leader>cr", "<cmd>CopilotChatReview<CR>", { desc = "CopilotChat - Review selection" })
map("v", "<leader>cf", "<cmd>CopilotChatFix<CR>", { desc = "CopilotChat - Fix selection" })
map("v", "<leader>co", "<cmd>CopilotChatOptimize<CR>", { desc = "CopilotChat - Optimize selection" })
map("v", "<leader>cd", "<cmd>CopilotChatDocs<CR>", { desc = "CopilotChat - Document selection" })
map("v", "<leader>ct", "<cmd>CopilotChatTests<CR>", { desc = "CopilotChat - Generate tests" })
map("n", "<leader>cp", "<cmd>CopilotChatToggle<CR>", { desc = "CopilotChat - Toggle chat" })

-- Copilot controls
map("n", "<leader>cs", "<cmd>Copilot status<CR>", { desc = "Copilot - Status" })
map("n", "<leader>ce", "<cmd>Copilot enable<CR>", { desc = "Copilot - Enable" })
map("n", "<leader>cD", "<cmd>Copilot disable<CR>", { desc = "Copilot - Disable" })

-- Python-specific keymaps
local function python_keymaps()
  local buf = vim.api.nvim_get_current_buf()
  local opts = { buffer = buf, noremap = true, silent = true }
  
  -- Format current buffer with Ruff
  map("n", "<leader>lf", function()
    LazyVim.format({ force = true })
  end, vim.tbl_extend("force", opts, { desc = "Format Python file" }))
  
  -- Organize imports
  map("n", "<leader>lo", function()
    vim.lsp.buf.code_action({
      filter = function(action)
        return action.kind and action.kind:match("source%.organizeImports")
      end,
      apply = true,
    })
  end, vim.tbl_extend("force", opts, { desc = "Organize Python imports" }))
  
  -- Run current Python file
  map("n", "<leader>rr", "<cmd>!python3 %<CR>", vim.tbl_extend("force", opts, { desc = "Run Python file" }))
  
  -- Python REPL
  map("n", "<leader>rp", "<cmd>terminal python3<CR>", vim.tbl_extend("force", opts, { desc = "Open Python REPL" }))
  
  -- Run Python tests (pytest)
  map("n", "<leader>rt", "<cmd>terminal pytest %<CR>", vim.tbl_extend("force", opts, { desc = "Run pytest on current file" }))
  map("n", "<leader>rT", "<cmd>terminal pytest<CR>", vim.tbl_extend("force", opts, { desc = "Run all pytest tests" }))
end

-- Auto-setup Python keymaps for Python files
vim.api.nvim_create_autocmd("FileType", {
  pattern = "python",
  callback = python_keymaps,
  desc = "Setup Python-specific keymaps",
})

-- Link opening keymaps
-- Note: gx mapping is already configured in the gx.nvim plugin

-- Additional link opening keymaps for convenience
map("n", "<leader>ol", "<cmd>Browse<CR>", { desc = "Open link under cursor" })
map("v", "<leader>ol", "<cmd>Browse<CR>", { desc = "Open selected link" })

-- Alternative keymaps for different contexts
map("n", "gl", "<cmd>Browse<CR>", { desc = "Open link under cursor (alternative)" })
map("v", "gl", "<cmd>Browse<CR>", { desc = "Open selected link (alternative)" })

-- Mouse support for link opening
-- These are configured in the gx.nvim plugin configuration with keys
-- but we add them here for documentation and potential fallbacks

-- Configure mouse scroll behavior to not interfere with link opening
-- Disable scroll wheel in normal mode to prevent accidental cursor movement
map("n", "<ScrollWheelUp>", "<C-y>", { desc = "Scroll up without moving cursor" })
map("n", "<ScrollWheelDown>", "<C-e>", { desc = "Scroll down without moving cursor" })

-- Middle mouse button for opening links (alternative to Shift+click)
map("n", "<MiddleMouse>", "<cmd>Browse<CR>", { desc = "Open link with middle mouse" })
map("v", "<MiddleMouse>", "<cmd>Browse<CR>", { desc = "Open selected link with middle mouse" })
