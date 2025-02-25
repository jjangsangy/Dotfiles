-- [[ Basic Keymaps ]]
--  See `:help vim.keymap.set()`

-- Clear highlights on search when pressing <Esc> in normal mode
--  See `:help hlsearch`
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")

-- Diagnostic keymaps
vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Open diagnostic [Q]uickfix list" })

-- Exit terminal mode in the builtin terminal with a shortcut that is a bit easier
-- for people to discover. Otherwise, you normally need to press <C-\><C-n>, which
-- is not what someone will guess without a bit more experience.
--
-- NOTE: This won't work in all terminal emulators/tmux/etc. Try your own mapping
-- or just use <C-\><C-n> to exit terminal mode
vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

-- Keybinds to make split navigation easier.
--  Use CTRL+<hjkl> to switch between windows
--
--  See `:help wincmd` for a list of all window commands
vim.keymap.set("n", "<C-h>", "<C-w><C-h>", { desc = "Move focus to the left window" })
vim.keymap.set("n", "<C-l>", "<C-w><C-l>", { desc = "Move focus to the right window" })
vim.keymap.set("n", "<C-j>", "<C-w><C-j>", { desc = "Move focus to the lower window" })
vim.keymap.set("n", "<C-k>", "<C-w><C-k>", { desc = "Move focus to the upper window" })

-- buffer management
vim.api.nvim_set_keymap("n", "<Right>", ":bnext<CR>", { noremap = true, desc = "Go to the next buffer" })
vim.api.nvim_set_keymap("n", "<Left>", ":bprevious<CR>", { noremap = true, desc = "Go to previous buffer" })

-- paste without replacing from register
vim.api.nvim_set_keymap("x", "<leader>p", '"_dP', { noremap = true, desc = "Paste without removing from register" })

-- visual move lines up and down
vim.keymap.set("v", "K", ":move '<-2<CR>gv=gv", { silent = true, desc = "Visual move lines up" })
vim.keymap.set("v", "J", ":move '>+1<CR>gv=gv", { silent = true, desc = "Visual move lines down" })

-- use J to move line below up without moving cursor
vim.keymap.set("n", "J", "mzJ`z", { desc = "Delete newline below without moving cursor" })

-- PageUp/PageDown half page jumping with cursor at center
vim.keymap.set("n", "<PageDown>", "<C-d>zz", { desc = "Half page jumping while cursor is at center" })
vim.keymap.set("n", "<PageUp>", "<C-u>zz", { desc = "Half page jumping while cursor is at center" })

-- hlsearch keeps cursor at center
vim.keymap.set("n", "n", "nzzzv", { desc = "hlsearch keeps cursor at center" })
vim.keymap.set("n", "N", "Nzzzv", { desc = "hlsearch keeps cursor at center" })

-- find and replace under cursor
vim.keymap.set(
  "n",
  "<C-r><C-s>",
  [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]],
  { desc = "Find and replace under cursor" }
)
