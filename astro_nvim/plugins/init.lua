return {
  -- theme
  'joshdick/onedark.vim',

  -- correct python indentation
   { 'Vimjas/vim-python-pep8-indent', ft = 'python' },
  -- {
  --   'mhartington/formatter.nvim',
  --   config = function()
  --     vim.api.nvim_create_augroup('fmt', { clear = true })
  --     vim.api.nvim_create_autocmd('BufWritePre', {
  --       group = 'fmt',
  --       pattern = '*.py',
  --       desc = 'run formatter on write to python file',
  --       command = 'FormatWrite'
  --     })
  --     require('formatter').setup({
  --       filetype = {
  --         python = {
  --           function()
  --             return {
  --               exe = "black",
  --               args = { '-' },
  --               stdin = true,
  --             }
  --           end
  --         }
  --       }
  --     })
  --   end
  -- }

  -- format python on save
  -- {
  --   'sbdchd/neoformat',
  --   ft = 'python',
  --   config = function ()
  --     vim.g.neoformat_enabled_python = { 'black' }
  --
  --     vim.api.nvim_create_augroup('fmt', { clear = true })
  --     vim.api.nvim_create_autocmd('BufWritePre', {
  --       group = 'fmt',
  --       pattern = '*.py',
  --       desc = 'run formatter on write to python file',
  --       command = 'Neoformat'
  --     })
  --   end
  -- },

}
