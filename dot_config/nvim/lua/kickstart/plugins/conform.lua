local oxfmt_config_files = {
  '.oxfmtrc.json',
  '.oxfmtrc.jsonc',
}

local function find_oxfmt_config(path)
  return vim.fs.find(oxfmt_config_files, { path = path, upward = true })[1]
end

return {
  { -- Autoformat
    'stevearc/conform.nvim',
    event = { 'BufWritePre' },
    cmd = { 'ConformInfo' },
    keys = {
      {
        '<leader>f',
        function()
          require('conform').format { async = true, lsp_format = 'never' }
        end,
        mode = '',
        desc = '[F]ormat buffer',
      },
    },
    opts = {
      notify_on_error = false,
      formatters = {
        oxfmt = {
          command = 'oxfmt',
          stdin = false,
          args = function(_, ctx)
            local config = find_oxfmt_config(ctx.dirname)
            if config then
              return { '--config', config, '$FILENAME' }
            end
            return { '$FILENAME' }
          end,
          cwd = function(_, ctx)
            local config = find_oxfmt_config(ctx.dirname)
            if config then
              return vim.fs.dirname(config)
            end
            return require('conform.util').root_file {
              'package.json',
              '.git',
            }(_, ctx)
          end,
          require_cwd = true,
        },
      },
      format_on_save = function(bufnr)
        -- Disable "format_on_save lsp_fallback" for languages that don't
        -- have a well standardized coding style. You can add additional
        -- languages here or re-enable it for the disabled ones.
        local disable_filetypes = { c = true, cpp = true }
        if disable_filetypes[vim.bo[bufnr].filetype] then
          return nil
        else
            return {
              timeout_ms = 500,
              lsp_format = 'never',
            }
        end
      end,
      formatters_by_ft = {
        lua = { 'stylua' },
        sh = { 'shfmt' },
        json = { 'oxfmt' },
        yaml = { 'oxfmt' },
        markdown = { 'oxfmt' },
        html = { 'oxfmt' },
        javascript = { 'oxfmt' },
        javascriptreact = { 'oxfmt' },
        typescript = { 'oxfmt' },
        typescriptreact = { 'oxfmt' },
        python = { 'isort', 'black' },
        nix = { 'alejandra' },
        make = { 'checkmake' },
        cs = { 'csharpier' },
        -- Conform can also run multiple formatters sequentially
        -- python = { "isort", "black" },
        --
        -- You can use 'stop_after_first' to run the first available formatter from the list
        -- javascript = { "oxfmt", "prettier", stop_after_first = true },
      },
    },
  },
}
-- vim: ts=2 sts=2 sw=2 et
