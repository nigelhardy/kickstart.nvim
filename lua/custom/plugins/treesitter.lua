return {
  { -- Highlight, edit, and navigate code
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate',
    main = 'nvim-treesitter.configs', -- Sets main module to use for opts
    -- [[ Configure Treesitter ]] See `:help nvim-treesitter`
    opts = {
      ensure_installed = {
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
      },
      -- Autoinstall languages that are not installed
      auto_install = true,
      highlight = {
        enable = true,
        -- Some languages depend on vim's regex highlighting system (such as Ruby) for indent rules.
        --  If you are experiencing weird indenting issues, add the language to
        --  the list of additional_vim_regex_highlighting and disabled languages for indent.
        additional_vim_regex_highlighting = { 'ruby' },
        -- Disable for OneDrive paths that might cause sync issues
        disable = function(lang, buf)
          local bufname = vim.api.nvim_buf_get_name(buf)
          -- Disable Treesitter for files in OneDrive if they're causing issues
          if bufname:match 'OneDrive' and lang == 'powershell' then
            return true
          end
          -- Disable for filetypes without available parsers
          if lang == 'git_config' then
            return true
          end
          return false
        end,
      },
      indent = { enable = true, disable = { 'ruby' } },
    },
    config = function(_, opts)
      -- Force Windows to compile parsers locally with clang
      if vim.fn.has 'win32' == 1 then
        require('nvim-treesitter.install').prefer_git = true
        require('nvim-treesitter.install').compilers = { 'clang', 'gcc' }
      end

      require('nvim-treesitter.configs').setup(opts)
    end,
    -- There are additional nvim-treesitter modules that you can use to interact
    -- with nvim-treesitter. You should go explore a few and see what interests you:
    --
    --    - Incremental selection: Included, see `:help nvim-treesitter-incremental-selection-mod`
    --    - Show your current context: https://github.com/nvim-treesitter/nvim-treesitter-context
    --    - Treesitter + textobjects: https://github.com/nvim-treesitter/nvim-treesitter-textobjects
  },
}