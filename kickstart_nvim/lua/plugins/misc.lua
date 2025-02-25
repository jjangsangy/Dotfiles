-- Standalone plugins with less than 10 lines of config go here
return {
  "tpope/vim-sleuth",
  "ThePrimeagen/vim-be-good",
  {
    "mbbill/undotree",
    config = function()
      vim.keymap.set("n", "<leader>u", vim.cmd.UndotreeToggle, { desc = "UndotreeToggle" })

      vim.opt.undofile = true
      vim.opt.undodir = os.getenv("HOME") .. "/.vim/undodir"
    end,
  },
}
