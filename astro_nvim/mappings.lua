return {
    n = {
        -- save file with ctrl-s
        ["<C-s>"] = { ":w!<CR>", desc = "Save File" },
        -- redo
        ["U"] = { "U", desc = "Redo" },
        -- toggle folding
        ["<Space>"] = { "za", desc = "Toggle Fold" },
        -- move buffers with left/right
        ["<Right>"] = { ":bnext<CR>", desc = "Move Buffer Right" },
        ["<Left>"] = { ":bprevious<CR>", desc = "Move Buffer Left" },
    },
    x = {
        -- keep paste in buffer
        ["<leader>p"] = {
            '"_dP',
            desc = "Paste into Permanant Buffer",
        },
    },
}
