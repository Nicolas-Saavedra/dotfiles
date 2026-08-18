vim.keymap.set('n', '<Space>lg', '<CMD>lua Snacks.lazygit()<CR>', { desc = 'Open [L]azy[G]it' })
vim.keymap.set('n', '<Space>gb', '<CMD>lua Snacks.git.blame_line()<CR>', { desc = '[G]it [B]lame the current line' })

--  Communicates Renames to LSP when using Oil.nvim
vim.api.nvim_create_autocmd('User', {
  pattern = 'OilActionsPost',
  callback = function(event)
    if event.data.actions.type == 'move' then
      Snacks.rename.on_rename_file(event.data.actions.src_url, event.data.actions.dest_url)
    end
  end,
})

return {
  'folke/snacks.nvim',
  priority = 1000,
  lazy = false,
  ---@type snacks.Config
  opts = {
    dashboard = {
      enabled = true,
      sections = {
        { section = 'header' },
        { section = 'startup' },
      },
      preset = {
        header = [[
                                                                     
       ████ ██████           █████      ██                     
      ███████████             █████                             
      █████████ ███████████████████ ███   ███████████   
     █████████  ███    █████████████ █████ ██████████████   
    █████████ ██████████ █████████ █████ █████ ████ █████   
  ███████████ ███    ███ █████████ █████ █████ ████ █████  
 ██████  █████████████████████ ████ █████ █████ ████ ██████ 
        ]],
      },
    },
    bigfile = { enabled = true },
    indent = { enabled = true },
    picker = { enabled = true },
    notifier = { enabled = true },
    quickfile = { enabled = true },
    scope = { enabled = true },
    scroll = { enabled = true, animate = {
      duration = {
        step = 28,
        total = 200,
      },
    } },
    statuscolumn = { enabled = true },
    words = { enabled = true },
    git = { enabled = true },
    lazygit = { enabled = true, configure = false },
    gitbrowse = { enabled = true },
  },
}
