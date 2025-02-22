return {
  "catppuccin/nvim",
  name = "catppuccin",
  priority = 800,
  config = function()
    require("catppuccin").setup({
      flavour = "frappe",
      dim_inactive = {
        enabled = true, -- dims the background color of inactive window
        shade = "dark",
        percentage = 0.15, -- percentage of the shade to apply to the inactive window
      },
    })
  end,
}
