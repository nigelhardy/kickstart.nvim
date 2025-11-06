return {
  'pmizio/typescript-tools.nvim',
  ft = { 'typescript', 'typescriptreact', 'javascript', 'javascriptreact' },
  dependencies = { 'nvim-lua/plenary.nvim', 'neovim/nvim-lspconfig' },
  config = function()
    require('typescript-tools').setup {
      settings = {
        separate_diagnostic_server = true,
        publish_diagnostic_on = 'insert_leave',
        expose_as_code_action = 'all',
        tsserver_plugins = {},
        tsserver_file_preferences = {
          includeInlayParameterNameHints = 'all',
          includeInlayVariableTypeHints = true,
        },
        tsserver_format_options = {
          allowIncompleteCompletions = false,
        },
      },
    }
  end,
}
