-- This file configures clangd LSP for C/C++ files
-- It depends on nvim-lspconfig being set up in init.lua first
return {
  'saghen/blink.cmp', -- Just need a plugin to hook into lazy.nvim's ft loading
  ft = { 'c', 'cpp', 'objc', 'objcpp', 'cuda', 'proto' },
  config = function()
    -- Only run if lspconfig hasn't been loaded yet
    -- This ensures the LspAttach autocmd from init.lua is set up first
    if not package.loaded['lspconfig'] then
      -- Force load the main lspconfig setup from init.lua
      require('lazy').load({ plugins = { 'nvim-lspconfig' } })
    end

    -- Get capabilities from blink.cmp
    local capabilities = require('blink.cmp').get_lsp_capabilities()

    -- Define clangd configuration using vim.lsp.config
    vim.lsp.config.clangd = {
      cmd = {
        'clangd',
        '--background-index',
        '--clang-tidy',
        '--header-insertion=iwyu',
        '--completion-style=detailed',
        '--function-arg-placeholders',
        '--fallback-style=llvm',
      },
      filetypes = { 'c', 'cpp', 'objc', 'objcpp', 'cuda', 'proto' },
      root_markers = {
        '.clangd',
        '.clang-tidy',
        '.clang-format',
        'compile_commands.json',
        'compile_flags.txt',
        'configure.ac',
        '.git',
      },
      capabilities = capabilities,
      init_options = {
        clangdFileStatus = true,
        usePlaceholders = true,
        completeUnimported = true,
        semanticHighlighting = true,
      },
    }

    -- Enable clangd
    vim.lsp.enable('clangd')
  end,
}
