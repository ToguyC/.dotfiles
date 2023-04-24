local rt = require("rust-tools")

local lsp_formatting = function(bufnr)
    vim.lsp.buf.format({
        filter = function(client)
            -- apply whatever logic you want (in this example, we'll only use null-ls)
            return client.name == "null-ls" or client.name == "rust_analyzer"
        end,
        bufnr = bufnr,
    })
end

-- need to override on_attach to keep custom mapping
local on_attach = function(client, bufnr)
  local opts = {buffer = bufnr, remap = false}

  vim.keymap.set("n", "gd", function() vim.lsp.buf.definition() end, opts)
  vim.keymap.set("n", "K", function() vim.lsp.buf.hover() end, opts)
  vim.keymap.set("n", "<leader>df", function() vim.diagnostic.open_float() end, opts)
  vim.keymap.set("n", "<leader>ca", function() rt.code_action_group.code_action_group() end, opts)
  vim.keymap.set("n", "<C-a>", function() rt.hover_actions.hover_actions() end, opts)
  vim.keymap.set("n", "<leader>rf", function() vim.lsp.buf.references() end, opts)
  vim.keymap.set("n", "<leader>rr", function() vim.lsp.buf.rename() end, opts)
  vim.keymap.set("n", "<leader>lf", function() lsp_formatting(bufnr) end, opts)
  vim.keymap.set("i", "<C-h>", function() vim.lsp.buf.signature_help() end, opts)
end

-- rt.inlay_hints.disable()

rt.setup({
  tools = {
      inlay_hints = {
          auto = false,
          show_parameter_hints = false,
          parameter_hints_prefix = false
      },
  },
  server = {
      on_attach = on_attach
  },
})
