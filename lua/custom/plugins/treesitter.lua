return {
  { -- Highlight, edit, and navigate code
    'nvim-treesitter/nvim-treesitter',
    -- The `master` branch is the old, incompatible-with-0.12 plugin; `main` is the
    -- rewrite required for Neovim >= 0.12. See `:help nvim-treesitter`
    branch = 'main',
    lazy = false, -- this plugin does not support lazy-loading
    build = ':TSUpdate',
    config = function()
      local ensure_installed = {
        'bash',
        'c',
        'diff',
        'gitcommit',
        'git_rebase',
        'html',
        'lua',
        'luadoc',
        'markdown',
        'markdown_inline',
        'powershell',
        'query',
        'vim',
        'vimdoc',
      }

      require('nvim-treesitter').install(ensure_installed)

      vim.api.nvim_create_autocmd('FileType', {
        callback = function(args)
          local lang = vim.treesitter.language.get_lang(args.match) or args.match

          -- Disable for filetypes without available parsers
          if lang == 'git_config' then
            return
          end

          -- Disable for files in OneDrive if they're causing sync issues
          local bufname = vim.api.nvim_buf_get_name(args.buf)
          if bufname:match 'OneDrive' and lang == 'powershell' then
            return
          end

          if not vim.tbl_contains(ensure_installed, lang) then
            return
          end

          local ok = pcall(vim.treesitter.start)
          if ok then
            vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
          end
        end,
      })
    end,
    -- There are additional nvim-treesitter modules that you can use to interact
    -- with nvim-treesitter. You should go explore a few and see what interests you:
    --
    --    - Incremental selection: Included, see `:help nvim-treesitter-incremental-selection-mod`
    --    - Show your current context: https://github.com/nvim-treesitter/nvim-treesitter-context
    --    - Treesitter + textobjects: https://github.com/nvim-treesitter/nvim-treesitter-textobjects
  },
}