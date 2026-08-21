return {
  { -- Highlight, edit, and navigate code
    'nvim-treesitter/nvim-treesitter',
    -- The `master` branch is frozen and does NOT support Neovim 0.12; `main` is
    -- the maintained rewrite. It has no `configs`/`setup{}` module anymore:
    -- parsers are installed with `require('nvim-treesitter').install()` and
    -- highlighting/indent are enabled per buffer via the builtin `vim.treesitter`.
    -- Requires the `tree-sitter` CLI (installed through mason-tool-installer).
    branch = 'main',
    lazy = false,
    build = ':TSUpdate',
    -- [[ Configure Treesitter ]] See `:help nvim-treesitter`
    config = function()
      local ts = require 'nvim-treesitter'

      -- Parsers that should always be present. Anything else is auto-installed
      -- the first time a matching filetype is opened (see the autocmd below).
      local ensure_installed = {
        -- kickstart defaults
        'bash', 'c', 'diff', 'html', 'lua', 'luadoc', 'markdown', 'markdown_inline', 'query', 'vim', 'vimdoc', 'json',
        -- languages used on this machine
        'css', 'csv', 'dockerfile', 'fish', 'git_config', 'git_rebase', 'gitcommit', 'gitignore', 'gleam', 'go',
        'hyprlang', 'ini', 'javascript', 'kdl', 'mermaid', 'pem', 'python', 'rasi', 'regex', 'requirements', 'rust',
        'sql', 'ssh_config', 'terraform', 'toml', 'tsx', 'typescript', 'udev', 'xml', 'yaml',
      }
      ts.install(ensure_installed)

      ---@param buf integer
      ---@param language string
      local function try_attach(buf, language)
        -- Check if a parser exists and load it
        if not vim.treesitter.language.add(language) then
          return
        end
        -- Enable syntax highlighting and other treesitter features
        vim.treesitter.start(buf, language)

        -- Enable treesitter based indentation when the language has an indent query;
        -- otherwise 'indentexpr' falls back to Vim's builtin indentation.
        if vim.treesitter.query.get(language, 'indents') ~= nil then
          vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end
      end

      local available = ts.get_available()
      vim.api.nvim_create_autocmd('FileType', {
        group = vim.api.nvim_create_augroup('kickstart-treesitter', { clear = true }),
        callback = function(args)
          local buf, filetype = args.buf, args.match
          local language = vim.treesitter.language.get_lang(filetype)
          if not language then
            return
          end

          if vim.tbl_contains(ts.get_installed 'parsers', language) then
            try_attach(buf, language)
          elseif vim.tbl_contains(available, language) then
            -- Auto-install missing parsers, then attach once the install finishes
            ts.install(language):await(function()
              if vim.api.nvim_buf_is_valid(buf) then
                try_attach(buf, language)
              end
            end)
          else
            -- Parser may exist outside nvim-treesitter (e.g. bundled with Neovim)
            try_attach(buf, language)
          end
        end,
      })
    end,
    -- There are additional nvim-treesitter modules that you can use to interact
    -- with nvim-treesitter. You should go explore a few and see what interests you:
    --
    --    - Show your current context: https://github.com/nvim-treesitter/nvim-treesitter-context
    --    - Treesitter + textobjects: https://github.com/nvim-treesitter/nvim-treesitter-textobjects (main branch)
  },
}
-- vim: ts=2 sts=2 sw=2 et
