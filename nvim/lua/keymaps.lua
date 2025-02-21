-- Key Remapping
--
local opts = { noremap = true }

-- <Ctrl>+hjkl for moving between splits
vim.api.nvim_set_keymap("n", "<C-h>", "<C-w>h", opts)
vim.api.nvim_set_keymap("n", "<C-j>", "<C-w>j", opts)
vim.api.nvim_set_keymap("n", "<C-k>", "<C-w>k", opts)
vim.api.nvim_set_keymap("n", "<C-l>", "<C-w>l", opts)

-- buffer management
vim.api.nvim_set_keymap("n", "<Right>", ":bnext<CR>", opts)
vim.api.nvim_set_keymap("n", "<Left>", ":bprevious<CR>", opts)

-- emacs style mappings
vim.api.nvim_set_keymap("n", "<C-e>", "<esc>$", opts)
vim.api.nvim_set_keymap("n", "<C-a>", "<esc>0", opts)
