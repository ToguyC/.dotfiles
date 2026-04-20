return {
  -- 1. Install the plugin
  {
    "loctvl842/monokai-pro.nvim",
    lazy = false, -- load at startup, not on demand
    priority = 1000, -- before anything else that depends on a colorscheme
    opts = {
      filter = "classic", -- "pro" | "octagon" | "machine" | "ristretto" | "spectrum" | "classic"
      transparent_background = false,
      terminal_colors = true,
      devicons = true,
      styles = {
        comment = { italic = true },
        keyword = { italic = false },
        type = { italic = false },
        storageclass = { italic = false },
        structure = { italic = false },
        parameter = { italic = false },
        annotation = { italic = false },
        tag_attribute = { italic = true },
      },
      -- Override specific colors to exactly match your bar palette
      override = function(c)
        return {
          -- Your exact theme.bg / theme.fg instead of Monokai Pro's defaults
          Normal = { fg = "#c8ccd4", bg = "#0f1114" },
          NormalFloat = { fg = "#c8ccd4", bg = "#1a1d23" },
          FloatBorder = { fg = "#2a2f38", bg = "#1a1d23" },
          SignColumn = { bg = "#0f1114" },
          LineNr = { fg = "#5c6370" },
          CursorLine = { bg = "#1a1d23" },
          CursorLineNr = { fg = "#a6e22e", bold = true },
          VertSplit = { fg = "#2a2f38" },
          WinSeparator = { fg = "#2a2f38" },
          StatusLine = { fg = "#c8ccd4", bg = "#1a1d23" },
          StatusLineNC = { fg = "#5c6370", bg = "#0f1114" },
          Pmenu = { fg = "#c8ccd4", bg = "#1a1d23" },
          PmenuSel = { fg = "#0f1114", bg = "#a6e22e" },
          Visual = { bg = "#2a2f38" },
          Search = { fg = "#0f1114", bg = "#f4bf75" },
          IncSearch = { fg = "#0f1114", bg = "#66d9ef" },
        }
      end,
    },
  },

  -- 2. Tell LazyVim to use it
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "monokai-pro",
    },
  },
}
