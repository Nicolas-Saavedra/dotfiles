return {
  'olimorris/codecompanion.nvim',
  cmd = { 'CodeCompanion', 'CodeCompanionChat', 'CodeCompanionActions' },
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-treesitter/nvim-treesitter',
  },
  opts = {
    ---@module "codecompanion"
    ---@type CodeCompanion.Config
    strategies = {
      chat = {
        adapter = {
          name = 'anthropic',
          model = 'claude-sonnet-4-20250514',
        },
      },
      inline = {
        adapter = {
          name = 'anthropic',
          model = 'claude-sonnet-4-20250514',
        },
      },
      cmd = {
        adapter = {
          name = 'anthropic',
          model = 'claude-sonnet-4-20250514',
        },
      },
    },
    display = {
      action_palette = {
        provider = 'default',
      },
      chat = {
        icons = {
          tool_success = '󰸞 ',
        },
        fold_context = true,
      },
      diff = {
        provider = 'mini_diff',
      },
    },
  },
  keys = {
    {
      '<C-a>',
      '<cmd>CodeCompanionActions<CR>',
      desc = 'Open the action palette',
      mode = { 'n', 'v' },
    },
    {
      '<Leader>a',
      '<cmd>CodeCompanionChat Toggle<CR>',
      desc = 'Toggle a chat buffer',
      mode = { 'n', 'v' },
    },
    {
      '<LocalLeader>a',
      '<cmd>CodeCompanionChat Add<CR>',
      desc = 'Add code to a chat buffer',
      mode = { 'v' },
    },
  },
  init = function()
    -- Expand 'cc' into 'CodeCompanion' in the command line
    vim.cmd [[cab cc CodeCompanion]]
  end,
}
