return {
  'Shatur/neovim-session-manager',
  dependencies = {
    'nvim-lua/plenary.nvim',
  },
  config = function()
    local Path = require('plenary.path')
    local config = require('session_manager.config')
    
    require('session_manager').setup({
      sessions_dir = Path:new(vim.fn.stdpath('data'), 'sessions'), -- The directory where the session files will be saved.
      autoload_mode = config.AutoloadMode.GitSession, -- Define what to do when Neovim is started without arguments.
      autosave_last_session = true, -- Automatically save last session on exit and on session switch.
      autosave_ignore_not_normal = true, -- Plugin will not save a session when no buffers are opened, or all of them aren't writable or listed.
      autosave_ignore_dirs = {}, -- A list of directories where the session will not be autosaved.
      autosave_ignore_filetypes = { -- All buffers of these file types will be closed before the session is saved.
        'gitcommit',
        'gitrebase',
      },
      autosave_ignore_buftypes = {}, -- All buffers of these buffer types will be closed before the session is saved.
      autosave_only_in_session = false, -- Always autosaves session. If true, only autosaves after a session is active.
      max_path_length = 80, -- Shorten the display path if length exceeds this threshold. Use 0 if don't want to shorten the path at all.
      load_include_current = false, -- The currently loaded session appears in the load_session UI.
    })
    
    -- Optional: Set up keymaps (using <leader>S to avoid conflicts with search)
    vim.keymap.set('n', '<leader>Sl', '<cmd>SessionManager load_session<cr>', { desc = '[S]ession [L]oad' })
    vim.keymap.set('n', '<leader>Ss', '<cmd>SessionManager save_current_session<cr>', { desc = '[S]ession [S]ave' })
    vim.keymap.set('n', '<leader>Sd', '<cmd>SessionManager delete_session<cr>', { desc = '[S]ession [D]elete' })
    vim.keymap.set('n', '<leader>SL', '<cmd>SessionManager load_last_session<cr>', { desc = '[S]ession Load [L]ast' })
    vim.keymap.set('n', '<leader>Sc', '<cmd>SessionManager load_current_dir_session<cr>', { desc = '[S]ession Load [C]urrent dir' })
  end,
}
