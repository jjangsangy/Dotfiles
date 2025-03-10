vim.opt.autoindent = true
vim.opt.autoread = true
vim.opt.backspace = "2"
vim.opt.backup = false
vim.opt.completeopt = { "menu", "menuone", "noselect" }
vim.opt.directory = "."
vim.opt.encoding = "utf-8"
vim.opt.expandtab = true
vim.opt.foldcolumn = "2"
vim.opt.foldlevelstart = 20
vim.opt.hlsearch = true
vim.opt.ignorecase = true
vim.opt.incsearch = true
vim.opt.laststatus = 2
vim.opt.list = true
vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }
vim.opt.mouse = "a"
vim.opt.number = true
vim.opt.ruler = true
vim.opt.scrolloff = 3
vim.opt.shiftwidth = 4
vim.opt.showcmd = true
vim.opt.signcolumn = "yes"
vim.opt.smartcase = true
vim.opt.smartindent = true
vim.opt.softtabstop = 4
vim.opt.splitright = true
vim.opt.swapfile = false
vim.opt.tabstop = 4
vim.opt.termguicolors = true
vim.opt.wildignore = "log/**,node_modules/**,target/**,tmp/**,*.rbc"
vim.opt.wildmenu = true
vim.opt.wildmode = "longest,list,full"
vim.opt.wrap = false
vim.opt.writebackup = false

pcall(vim.cmd, "colorscheme onedark")
