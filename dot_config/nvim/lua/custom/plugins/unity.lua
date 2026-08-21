-- C# / Unity: Roslyn language server via roslyn.nvim.
--
-- roslyn.nvim owns the client lifecycle (solution discovery, `solution/open`
-- handshake, :Roslyn commands), so the mason `roslyn` package is installed via
-- mason-tool-installer but EXCLUDED from mason-lspconfig's automatic_enable
-- (see kickstart/plugins/lspconfig.lua) — same arrangement as rustaceanvim.
--
-- Unity only emits the .sln/.csproj this server needs through its IDE
-- package; the `code`-named shim in ~/.local/share/unity-nvim makes the
-- Visual Studio Editor package generate them and route file:line to the
-- nvim server listening on $XDG_RUNTIME_DIR/nvim-unity.sock.
return {
  'seblyng/roslyn.nvim',
  ft = 'cs',
  ---@module 'roslyn.config'
  ---@type RoslynNvimConfig
  opts = {
    filewatching = 'roslyn', -- Unity rewrites .csproj often; let the LS watch them
    broad_search = true, -- find the .sln from files opened deep under Assets/
  },
  config = function(_, opts)
    vim.lsp.config('roslyn', {
      settings = {
        ['csharp|background_analysis'] = {
          dotnet_analyzer_diagnostics_scope = 'openFiles',
          dotnet_compiler_diagnostics_scope = 'fullSolution',
        },
        ['csharp|inlay_hints'] = {
          csharp_enable_inlay_hints_for_implicit_variable_types = true,
          dotnet_enable_inlay_hints_for_parameters = true,
        },
        ['csharp|code_lens'] = {
          dotnet_enable_references_code_lens = true,
        },
      },
    })
    require('roslyn').setup(opts)
  end,
}
-- vim: ts=2 sts=2 sw=2 et
