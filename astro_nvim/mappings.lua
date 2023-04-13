return {
    n = {
        -- Save File with Ctrl-s
        ["<C-s>"] = { ":w!<CR>", desc = "Save File" },
        -- Redo
        ["U"] = { "U", desc = "Redo" },
        -- Toggle Folding
        ["<Space>"] = { "za", desc = "Toggle Fold" },
        -- move buffers with left/right
        ["<Right>"] = { ":bnext<CR>", desc = "Move Buffer Right" },
        ["<Left>"] = { ":bprevious<CR>", desc = "Move Buffer Left" },
    },
}
