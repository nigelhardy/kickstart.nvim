-- Mini.nvim configuration with simplified git-aware bookmarks
-- This file configures the mini.nvim plugin with basic bookmark functionality

return {
  'echasnovski/mini.nvim',
  config = function()
    -- Better Around/Inside textobjects
    --
    -- Examples:
    --  - va)  - [V]isually select [A]round [)]paren
    --  - yinq - [Y]ank [I]nside [N]ext [Q]uote
    --  - ci'  - [C]hange [I]nside [']quote
    require('mini.ai').setup { n_lines = 500 }

    -- Add/delete/replace surroundings (brackets, quotes, etc.)
    --
    -- - saiw) - [S]urround [A]dd [I]nner [W]ord [)]Paren
    -- - sd'   - [S]urround [D]elete [']quotes
    -- - sr)'  - [S]urround [R]eplace [)] [']
    require('mini.surround').setup()

    -- File explorer with better visuals
    local show_dotfiles = true
    local filter_show = function(fs_entry)
      return show_dotfiles or not vim.startswith(fs_entry.name, '.')
    end

    local toggle_dotfiles = function()
      show_dotfiles = not show_dotfiles
      MiniFiles.refresh { content = { filter = filter_show } }
    end

    local preview_enabled = true
    local toggle_preview = function()
      preview_enabled = not preview_enabled
      MiniFiles.refresh { windows = { preview = preview_enabled } }
    end

    require('mini.files').setup {
      windows = {
        preview = true, -- Enable preview pane
        width_focus = 30,
        width_preview = 80,
      },
      options = {
        use_as_default_explorer = true,
      },
      content = {
        filter = filter_show,
        sort = nil,
      },
      mappings = {
        close = 'q',
        go_in = 'l',
        go_in_plus = 'L',
        go_out = 'h',
        go_out_plus = 'H',
        mark_goto = "'",
        mark_set = 'm',
        reset = '<BS>',
        show_help = 'g?',
        synchronize = '=',
        trim_left = '<',
        trim_right = '>',
      },
    }

    -- Toggle hidden files and preview keybindings
    vim.api.nvim_create_autocmd('User', {
      pattern = 'MiniFilesBufferCreate',
      callback = function(args)
        vim.keymap.set('n', 'g.', toggle_dotfiles, { buffer = args.data.buf_id, desc = 'Toggle hidden files' })
        vim.keymap.set('n', 'gp', toggle_preview, { buffer = args.data.buf_id, desc = 'Toggle preview' })
        vim.keymap.set('n', 'gz', function()
          local path = MiniFiles.get_fs_entry().path
          local dir = vim.fn.isdirectory(path) == 1 and path or vim.fn.fnamemodify(path, ':h')
          vim.cmd('cd ' .. vim.fn.fnameescape(dir))
          vim.notify('CWD: ' .. dir)
        end, { buffer = args.data.buf_id, desc = 'Set cwd to current location' })
      end,
    })
    vim.keymap.set('n', '<leader>e', function()
      require('mini.files').open(vim.api.nvim_buf_get_name(0))
    end, { desc = 'Open mini.files at current file' })

    vim.keymap.set('n', '\\', function()
      if vim.bo.filetype == 'minifiles' then
        require('mini.files').close()
      else
        require('mini.files').open()
      end
    end, { desc = 'Toggle mini.files' })

    -- Simplified git-aware bookmark functionality
    local MiniFiles = require('mini.files')

    -- Git utility functions
    local git_utils = {}
    
    -- Get git repository root directory
    function git_utils.get_repo_root(path)
      path = path or vim.fn.getcwd()
      local cmd = 'git -C "' .. path .. '" rev-parse --show-toplevel 2>/dev/null'
      local result = vim.fn.system(cmd):gsub('%s+$', '')
      return vim.v.shell_error == 0 and result or nil
    end
    
    -- Get primary remote URL for repository
    function git_utils.get_remote_url(path)
      path = path or vim.fn.getcwd()
      local repo_root = git_utils.get_repo_root(path)
      if not repo_root then
        return nil
      end
      
      -- Try origin first, then first available remote
      local cmd = 'git -C "' .. repo_root .. '" remote get-url origin 2>/dev/null || git -C "' .. repo_root .. '" remote -v | head -n1 | cut -f2 | cut -d" " -f1'
      local result = vim.fn.system(cmd):gsub('%s+$', '')
      return vim.v.shell_error == 0 and result or nil
    end
    
    -- Convert repo-relative path to absolute path
    function git_utils.to_absolute_path(rel_path, repo_root)
      repo_root = repo_root or git_utils.get_repo_root()
      if not repo_root then
        return rel_path
      end
      
      return repo_root .. '/' .. rel_path
    end

    -- Simplified bookmark storage system
    local bookmarks_file = vim.fn.stdpath 'data' .. '/mini-files-bookmarks.lua'

    local load_bookmarks = function()
      local ok, bookmarks = pcall(dofile, bookmarks_file)
      if ok and type(bookmarks) == 'table' then
        -- Initialize structure if missing
        if not bookmarks.git_bookmarks then
          bookmarks.git_bookmarks = {}
        end
        if not bookmarks.global_bookmarks then
          bookmarks.global_bookmarks = {}
        end
        return bookmarks
      end
      
      -- Return default structure
      return {
        git_bookmarks = {},
        global_bookmarks = {}
      }
    end

    -- Get current context (repo info or global)
    local get_current_context = function()
      local repo_root = git_utils.get_repo_root()
      local remote_url = repo_root and git_utils.get_remote_url() or nil
      
      return {
        repo_root = repo_root,
        remote_url = remote_url,
        is_git_repo = repo_root ~= nil
      }
    end

    -- Load bookmarks once at startup
    local load_bookmarks_once = function()
      local bookmarks = load_bookmarks()
      local context = get_current_context()
      local loaded_count = 0
      
      if context.is_git_repo and context.remote_url then
        -- Load git-specific bookmarks
        local repo_bookmarks = bookmarks.git_bookmarks[context.remote_url] or {}
        
        for id, mark in pairs(repo_bookmarks) do
          if mark.path then
            -- Convert relative paths to absolute for mini.files
            local abs_path = git_utils.to_absolute_path(mark.path, context.repo_root)
            -- mini.files bookmarks need directory paths, not file paths
            local bookmark_dir = vim.fn.isdirectory(abs_path) == 1 and abs_path or vim.fn.fnamemodify(abs_path, ':h')
            MiniFiles.set_bookmark(id, bookmark_dir)
            loaded_count = loaded_count + 1
          end
        end
        
        if loaded_count > 0 then
          local repo_name = context.remote_url:match('([^/]+)%.git$') or context.remote_url
          vim.notify('Loaded ' .. loaded_count .. ' bookmarks for repo: ' .. repo_name, vim.log.levels.INFO)
        end
      else
        -- Load global bookmarks
        for id, mark in pairs(bookmarks.global_bookmarks) do
          if mark.path then
            -- mini.files bookmarks need directory paths, not file paths
            local bookmark_dir = vim.fn.isdirectory(mark.path) == 1 and mark.path or vim.fn.fnamemodify(mark.path, ':h')
            MiniFiles.set_bookmark(id, bookmark_dir)
            loaded_count = loaded_count + 1
          end
        end
        
        if loaded_count > 0 then
          vim.notify('Loaded ' .. loaded_count .. ' global bookmarks', vim.log.levels.INFO)
        end
      end
    end

    -- Load bookmarks when mini.files opens (once per session)
    local bookmarks_loaded = false
    vim.api.nvim_create_autocmd('User', {
      pattern = 'MiniFilesExplorerOpen',
      callback = function()
        if not bookmarks_loaded then
          load_bookmarks_once()
          bookmarks_loaded = true
        end
      end,
    })

    -- Simple keybinding to edit bookmarks file
    vim.api.nvim_create_autocmd('User', {
      pattern = 'MiniFilesBufferCreate',
      callback = function(args)
        vim.keymap.set('n', 'be', function()
          MiniFiles.close()
          vim.cmd('edit ' .. bookmarks_file)
        end, { buffer = args.data.buf_id, desc = '[B]ookmarks [E]dit' })
      end,
    })

    -- Simple and easy statusline.
    --  You could remove this setup call if you don't like it,
    --  and try some other statusline plugin
    local statusline = require 'mini.statusline'
    -- set use_icons to true if you have a Nerd Font
    statusline.setup { use_icons = vim.g.have_nerd_font }

    -- You can configure sections in the statusline by overriding their
    -- default behavior. For example, here we set the section for
    -- cursor location to LINE:COLUMN
    ---@diagnostic disable-next-line: duplicate-set-field
    statusline.section_location = function()
      return '%2l:%-2v'
    end

    -- ... and there is more!
    --  Check out: https://github.com/echasnovski/mini.nvim
  end,
}