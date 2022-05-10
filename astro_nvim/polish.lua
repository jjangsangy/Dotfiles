return function()
  -- set key bindings
  local map_opts = { noremap = true }

  -- save with ctrl-s
  vim.keymap.set("n", "<C-s>", ":w!<CR>", map_opts)

  -- redo key mapped to U
  vim.keymap.set("n", "U", ":redo<CR>", map_opts)

  -- move buffers with left/right
  vim.api.nvim_set_keymap("n", "<Right>", ":bnext<CR>", map_opts)
  vim.api.nvim_set_keymap("n", "<Left>", ":bprevious<CR>", map_opts)

  -- set autocommands
  vim.api.nvim_create_augroup("packer_conf", { clear = true })
  vim.api.nvim_create_autocmd("BufWritePost", {
    desc = "Sync packer after modifying plugins.lua",
    group = "packer_conf",
    pattern = "plugins.lua",
    command = "source <afile> | PackerSync",
  })

  -- microsoft clipboard
  if vim.call("system", "uname -r"):match("[Mm]icrosoft") then
    vim.api.nvim_create_augroup("Yank", {
      clear = true,
    })
    vim.api.nvim_create_autocmd("TextYankPost", {
      group = "Yank",
      pattern = "*",
      command = ":call system('/mnt/c/windows/system32/clip.exe ',@\")",
    })
    vim.api.nvim_create_autocmd("VimLeave", {
      group = "Yank",
      pattern = "*",
      command = "set guicursor=a:ver25blinkon100",
    })
  end
end
