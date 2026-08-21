return {
  'luckasRanarison/tailwind-tools.nvim',
  name = 'tailwind-tools',
  build = ':UpdateRemotePlugins',
  dependencies = {
    'nvim-treesitter/nvim-treesitter',
    'nvim-telescope/telescope.nvim', -- optional
    'neovim/nvim-lspconfig', -- optional
  },
  opts = {
    server = {
      -- The plugin's own server setup goes through the deprecated
      -- `require('lspconfig').tailwindcss.setup {}` framework (prints a backtrace).
      -- mason-lspconfig already enables `tailwindcss` via `vim.lsp.enable()`;
      -- the bits the plugin would have added are replicated below.
      override = false,
    },
  },
  config = function(_, opts)
    require('tailwind-tools').setup(opts)
    vim.lsp.config('tailwindcss', {
      capabilities = {
        textDocument = { colorProvider = { dynamicRegistration = true } },
      },
      settings = {
        tailwindCSS = {
          includeLanguages = require('tailwind-tools.filetypes').get_server_map(),
        },
      },
    })
  end,
}
