-- automatically bootstrap packer
local fn = vim.fn
local install_path = fn.stdpath('data')..'/site/pack/packer/start/packer.nvim'
if fn.empty(fn.glob(install_path, nil, nil)) > 0 then
  PACKER_BOOTSTRAP = fn.system({
      'git', 'clone', '--depth', '1', 'https://github.com/wbthomason/packer.nvim', install_path
  })
end


require('packer').startup(function(use)
    -- packer can manage itself
    use 'wbthomason/packer.nvim'

    -- colorscheme
    use 'joshdick/onedark.vim'

    -- improved buffer search
    use 'junegunn/vim-slash'

    -- replace 'tpope/vim-surround'
    use {
      'ur4ltz/surround.nvim',
      config = function()
        require("surround").setup({
            mappings_style = "sandwich"
        })
      end
    }

    -- replace vim-airline
    use {
      'nvim-lualine/lualine.nvim',
      requires = { 'kyazdani42/nvim-web-devicons', opt = true },
      config = function ()
          require('lualine').setup({
            options = {
              theme = 'onedark',
              icons_enabled = true,
            }
          })
      end
    }

    -- underline cursor word
    use {
        'yamatsum/nvim-cursorline',
        config = function ()
            require('nvim-cursorline').setup{}
        end
    }
    -- black formatter
    use {
        'psf/black',
         tag = "stable",
         config = function ()
             local group = vim.api.nvim_create_augroup('black_on_save', {
                 clear = true
             })
             vim.api.nvim_create_autocmd('BufWritePre', {
                 command = 'Black', group = group, pattern = '*.py'
             })
             vim.g.black_quiet = 1
        end,
        ft = 'python',
    }

    use {
        "folke/lua-dev.nvim",
        config = function()
            local luadev = require("lua-dev").setup{}
            local lspconfig = require('lspconfig')
            luadev.settings.Lua.diagnostics = {
                globals = { 'vim', 'require', 'pcall', 'ipairs' }
            }
            lspconfig.sumneko_lua.setup(luadev)
        end
    }

    -- correct python indentation
    use {
        'Vimjas/vim-python-pep8-indent',
        ft = 'python'
    }

    use {
        'kyazdani42/nvim-tree.lua',
        requires = {
          'kyazdani42/nvim-web-devicons', -- optional, for file icon
        },
        config = function()
            require'nvim-tree'.setup{}
            vim.api.nvim_set_keymap('n', '<C-n>', ':NvimTreeToggle<CR>', { noremap = true })
        end
    }

   -- comment with [gcc|gbc]
   use {
       'numToStr/Comment.nvim',
       config = function()
           require('Comment').setup{}
       end
   }

   -- replace 'jiangmiao/auto-pairs'
   use {
       'windwp/nvim-autopairs',
       config = function ()
           require('nvim-autopairs').setup({
               map_cr = true,
           })
            local ok, cmp = pcall(require, 'cmp')
            if ok then
                local cmp_autopairs = require('nvim-autopairs.completion.cmp')
                cmp.event:on( 'confirm_done', cmp_autopairs.on_confirm_done({  map_char = { tex = '' } }))
            end
       end
   }

   -- lsp and auto-completion
   use 'hrsh7th/cmp-buffer'
   use 'hrsh7th/cmp-cmdline'
   use 'hrsh7th/cmp-nvim-lsp'
   use 'hrsh7th/cmp-path'
   use 'hrsh7th/nvim-cmp'
   use 'neovim/nvim-lspconfig'

   -- For vsnip users.
   use 'hrsh7th/cmp-vsnip'
   use 'hrsh7th/vim-vsnip'

   -- tree-sitter
   use {
       'nvim-treesitter/nvim-treesitter',
        run = ':TSUpdate',
        config = function()
        -- nvim treesitter config
        require('nvim-treesitter.configs').setup({
            -- A list of parser names, or "all"
            ensure_installed = { "c", "lua", "rust", "fish", "python" },

            -- Install parsers synchronously (only applied to `ensure_installed`)
            sync_install = false,

            -- List of parsers to ignore installing (for "all")
            ignore_install = { "javascript" },

            highlight = {
              -- `false` will disable the whole extension
              enable = true,

              -- NOTE: these are the names of the parsers and not the filetype. (for example if you want to
              -- disable highlighting for the `tex` filetype, you need to include `latex` in this list as this is
              -- the name of the parser)
              -- list of language that will be disabled
              disable = { "c", "rust" },

              -- Setting this to true will run `:h syntax` and tree-sitter at the same time.
              -- Set this to `true` if you depend on 'syntax' being enabled (like for indentation).
              -- Using this option may slow down your editor, and you may see some duplicate highlights.
              -- Instead of true it can also be a list of languages
              additional_vim_regex_highlighting = false,
            },
        })
       end
   }

  if PACKER_BOOTSTRAP then
    require('packer').sync()
  end

end)

local cmp = require('cmp')

local has_words_before = function()
  local line, col = unpack(vim.api.nvim_win_get_cursor(0))
  return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
end

-- Global setup.
cmp.setup({
  snippet = {
    expand = function(args)
      vim.fn["vsnip#anonymous"](args.body) -- For `vsnip` users.
      -- require('luasnip').lsp_expand(args.body) -- For `luasnip` users.
      -- require'snippy'.expand_snippet(args.body) -- For `snippy` users.
      -- vim.fn["UltiSnips#Anon"](args.body) -- For `ultisnips` users.
    end,
  },
  window = {
    -- completion = cmp.config.window.bordered(),
    -- documentation = cmp.config.window.bordered(),
  },
  mapping = cmp.mapping.preset.insert({
    ['<C-d>'] = cmp.mapping.scroll_docs(-4),
    ['<C-f>'] = cmp.mapping.scroll_docs(4),
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<CR>'] = cmp.mapping.confirm({ select = true }),
    ['<Tab>'] = cmp.mapping(function(fallback)
        if cmp.visible() then
            cmp.select_next_item()
        elseif has_words_before() then
            cmp.complete()
        else
            fallback() -- The fallback function sends a already mapped key. In this case, it's probably `<Tab>`.
        end
    end, { "i", "s" }),
    ["<S-Tab>"] = cmp.mapping(function()
      if cmp.visible() then
        cmp.select_prev_item()
      end
    end, { "i", "s" }),
  }),
  sources = cmp.config.sources({
    { name = 'nvim_lsp' },
    { name = 'vsnip' }, -- For vsnip users.
    -- { name = 'luasnip' }, -- For luasnip users.
    -- { name = 'snippy' }, -- For snippy users.
    -- { name = 'ultisnips' }, -- For ultisnips users.
  }, {
    { name = 'buffer' },
  })
})

-- `/` cmdline setup.
cmp.setup.cmdline('/', {
  mapping = cmp.mapping.preset.cmdline(),
  sources = {
    { name = 'buffer' }
  }
})

-- `:` cmdline setup.
cmp.setup.cmdline(':', {
  mapping = cmp.mapping.preset.cmdline(),
  sources = cmp.config.sources({
    { name = 'path' }
  }, {
    { name = 'cmdline' }
  })
})

-- Setup lspconfig.
local capabilities = require('cmp_nvim_lsp').update_capabilities(vim.lsp.protocol.make_client_capabilities())
local lspconfig = require('lspconfig')

-- Enable some language servers with the additional completion capabilities offered by nvim-cmp
local servers = { 'clangd', 'rust_analyzer', 'pyright', 'tsserver' }
for _, lsp in ipairs(servers) do
  lspconfig[lsp].setup {
    -- on_attach = my_custom_on_attach,
    capabilities = capabilities,
  }
end

