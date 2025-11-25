-- Mini.nvim configuration with bookmark functionality
-- This file configures the mini.nvim plugin and extends it with git-aware bookmarks

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

    -- Quick jump to letter in mini.files
    vim.api.nvim_create_autocmd('FileType', {
      pattern = 'minifiles',
      callback = function()
        vim.keymap.set('n', 'g/', function()
          local char = vim.fn.getchar()
          if char then
            local letter = vim.fn.nr2char(tonumber(char) or 0)
            -- Account for icons (about 7 chars) before filename
            local pattern = '^.......' .. letter
            local line = vim.fn.search(pattern, 'W')
            if line == 0 then
              vim.notify('No line starting with "' .. letter .. '" found', vim.log.levels.INFO)
            end
          end
        end, { desc = 'Jump to line starting with letter', buffer = true })
      end,
    })

    -- Bookmark functionality (Phase 1: Extract from init.lua)
    local MiniFiles = require('mini.files')

    -- Load bookmarks from file on startup only (no auto-save)
    local bookmarks_file = vim.fn.stdpath 'data' .. '/mini-files-bookmarks.lua'

    local load_bookmarks = function()
      local ok, bookmarks = pcall(dofile, bookmarks_file)
      if ok and type(bookmarks) == 'table' then
        return bookmarks
      end
      return {}
    end

    local set_mark = function(id, path)
      MiniFiles.set_bookmark(id, path)
    end

    -- Load bookmarks when mini.files explorer opens
    vim.api.nvim_create_autocmd('User', {
      pattern = 'MiniFilesExplorerOpen',
      callback = function()
        -- Load bookmarks from file on first open
        local bookmarks = load_bookmarks()
        if bookmarks and next(bookmarks) then
          for id, mark in pairs(bookmarks) do
            if mark.path then
              set_mark(id, mark.path)
            end
          end
        end
      end,
    })

    -- Additional mini.files keybindings
    vim.api.nvim_create_autocmd('User', {
      pattern = 'MiniFilesBufferCreate',
      callback = function(args)
        local buf_id = args.data.buf_id

        -- Open bookmarks file for editing
        vim.keymap.set('n', 'bm', function()
          MiniFiles.close()
          vim.cmd('edit ' .. bookmarks_file)
        end, { buffer = buf_id, desc = 'Edit bookmarks file' })
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