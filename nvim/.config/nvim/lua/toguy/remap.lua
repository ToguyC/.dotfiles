local function map(mode, lhs, rhs, opts)
	local options = { noremap = true }
	if opts then
		options = vim.tbl_extend("force", options, opts)
	end
	vim.api.nvim_set_keymap(mode, lhs, rhs, options)
end

map("n", "<C-H>", "<C-W><C-H>")
map("n", "<C-J>", "<C-W><C-J>")
map("n", "<C-K>", "<C-W><C-K>")
map("n", "<C-L>", "<C-W><C-L>")
map("n", "<C-C>", "<C-W><C-C>")
map("t", "<C-H>", "<C-\\><C-n><C-W><C-H>")
map("t", "<C-J>", "<C-\\><C-n><C-W><C-J>")
map("t", "<C-K>", "<C-\\><C-n><C-W><C-K>")
map("t", "<C-L>", "<C-\\><C-n><C-W><C-L>")
map("t", "<C-X>", "<C-\\><C-n><C-W><C-C>")

map("n", "<A-k>", "[e", { noremap = false })
map("n", "<A-j>", "]e", { noremap = false })
map("v", "<A-k>", "[egv", { noremap = false })
map("v", "<A-j>", "]egv", { noremap = false })
