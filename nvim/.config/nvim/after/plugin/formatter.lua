local util = require "formatter.util"

require("formatter").setup({
    logging = true,
    log_level = vim.log.levels.WARN,
    filetype = {
        python = {
            require("formatter.filetypes.python").black,
            require("formatter.filetypes.python").isort
        },
        c = {
            require("formatter.filetypes.c").clangformat
        },
        cpp = {
            require("formatter.filetypes.c").clangformat
        },
        lua = {
            require("formatter.filetypes.lua").stylelua
        },

        ["*"] = {
            require("formatter.filetypes.any").remove_trailing_whitespace
        }
    }
})
