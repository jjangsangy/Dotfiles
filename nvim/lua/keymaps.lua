-- Key Remapping

-- <Ctrl>+hjkl for moving between splits
vim.api.nvim_set_keymap('n', '<C-h>', '<C-w>h', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<C-j>', '<C-w>j', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<C-k>', '<C-w>k', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<C-l>', '<C-w>l', { noremap = true, silent = true })

-- buffer management
vim.api.nvim_set_keymap('n', '<Right>', ':bnext<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<Left>', ':bprevious<CR>', { noremap = true, silent = true })

-- emacs style mappings
vim.api.nvim_set_keymap('n', '<C-e>', '<esc>$', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<C-a>', '<esc>0', { noremap = true, silent = true })
