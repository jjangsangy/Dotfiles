return function()
  local status_ok, null_ls = pcall(require, "null-ls")
  if not status_ok then
    return
  end
  -- Check supported formatters
  -- https://github.com/jose-elias-alvarez/null-ls.nvim/tree/main/lua/null-ls/builtins/formatting
  local formatting = null_ls.builtins.formatting

  -- Check supported linters
  -- https://github.com/jose-elias-alvarez/null-ls.nvim/tree/main/lua/null-ls/builtins/diagnostics
  local diagnostics = null_ls.builtins.diagnostics

  null_ls.setup {
    debug = false,
    sources = {
      diagnostics.jsonlint,
      diagnostics.fish,
      formatting.stylua.with {
        extra_args = {
          "--indent-type",
          "Spaces",
          "--indent-width",
          "2",
          "--call-parentheses",
          "NoSingleTable",
        },
      },
      formatting.fish_indent,
      formatting.black,
      formatting.isort.with {
        extra_args = { "--profile", "black" },
      },
    },

    -- format on save
    on_attach = function(client)
      if client.resolved_capabilities.document_formatting then
        vim.api.nvim_create_autocmd("BufWritePre", {
          desc = "Auto format before save",
          pattern = "<buffer>",
          callback = vim.lsp.buf.formatting_sync,
        })
      end
    end,
  }
end
