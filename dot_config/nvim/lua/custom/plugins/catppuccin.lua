--  Setup for my favorite colorscheme right now; Catppuccin
return {
  'catppuccin/nvim',
  name = 'catppuccin',
  priority = 1000,
  config = function()
    ---@diagnostic disable-next-line: missing-fields
    require('catppuccin').setup {
      transparent_background = true,
    }

    vim.cmd.colorscheme 'catppuccin-mocha'
  end,
}
