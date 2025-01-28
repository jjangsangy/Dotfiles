return {
  -- theme
  "joshdick/onedark.vim",

  -- correct python indentation
  { "Vimjas/vim-python-pep8-indent", ft = "python" },
  -- replace 'tpope/vim-surround'
  {
    "ur4ltz/surround.nvim",
    config = function()
      require("surround").setup {
        mappings_style = "sandwich",
      }
    end,
  },
}
