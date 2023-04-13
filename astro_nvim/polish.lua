return function()
  local ls = require("luasnip")

  require("luasnip.loaders.from_lua").load {
    paths = "~/.config/nvim/lua/user/snippets/",
  }

  local types = require("luasnip.util.types")
  ls.config.set_config {
    history = true,                            --keep around last snippet local to jump back
    updateevents = "TextChanged,TextChangedI", --update changes as you type
    enable_autosnippets = true,
    ext_opts = {
      [types.choiceNode] = {
        active = {
          virt_text = { { "●", "GruvboxOrange" } },
        },
      },
    },
  }

  -- <C-k> jump forward snip
  vim.keymap.set({ "i", "s" }, "<C-k>", function()
    if ls.expand_or_jumpable() then
      ls.expand_or_jump()
    end
  end, { silent = true })

  -- <C-j> jump backward snip
  vim.keymap.set({ "i", "s" }, "<C-j>", function()
    if ls.jumpable(-1) then
      ls.jump(-1)
    end
  end, { silent = true })

  -- <C-l> list snip choices
  vim.keymap.set({ "i", "s" }, "<C-l>", function()
    if ls.choice_active() then
      ls.change_choice(1)
    end
  end)

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

  -- disable inline diagnostics
  vim.diagnostic.config {
    virtual_text = false,
  }
  -- Show line diagnostics automatically in hover window
  vim.o.updatetime = 250
  vim.cmd([[autocmd CursorHold,CursorHoldI * lua vim.diagnostic.open_float(nil, {focus=false})]])
end
