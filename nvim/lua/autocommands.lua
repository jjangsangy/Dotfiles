-- filetype autocommands
local ftconfig_group = vim.api.nvim_create_augroup("ftconfig", {
	clear = true,
})
vim.api.nvim_create_autocmd("FileType", {
	group = ftconfig_group,
	pattern = "Makefile",
	command = "setlocal noet",
})
vim.api.nvim_create_autocmd("FileType", {
	group = ftconfig_group,
	pattern = "vim",
	command = "setlocal fdm=marker shiftwidth=2",
})
vim.api.nvim_create_autocmd("FileType", {
	group = ftconfig_group,
	pattern = "sshconfig",
	command = "setlocal shiftwidth=2",
})
vim.api.nvim_create_autocmd("FileType", {
	group = ftconfig_group,
	pattern = "fish",
	command = "setlocal omnifunc=v:lua.vim.slp.omnifunc",
})

-- microsoft clipboard
if vim.call("system", "uname -r"):match("[Mm]icrosoft") then
	local yank_group = vim.api.nvim_create_augroup("Yank", {
		clear = true,
	})
	vim.api.nvim_create_autocmd("TextYankPost", {
		group = yank_group,
		pattern = "*",
		command = ":call system('/mnt/c/windows/system32/clip.exe ',@\")",
	})
	vim.api.nvim_create_autocmd("VimLeave", {
		group = yank_group,
		pattern = "*",
		command = "set guicursor=a:ver25blinkon100",
	})
end
