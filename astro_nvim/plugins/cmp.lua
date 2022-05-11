local ls = require("luasnip")

return {
  mapping = {
    ["<C-k>"] = function()
      if ls.expand_or_jumpable() then
        ls.expand_or_jump()
      end
    end,
    ["<C-j>"] = function()
      if ls.jumpable(-1) then
        ls.jump(-1)
      end
    end,
  },
}
