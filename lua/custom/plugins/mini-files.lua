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



    -- Git-aware bookmark functionality (Phase 2: Git repository detection and storage)
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
    
    -- Convert absolute path to repo-relative path
    function git_utils.to_relative_path(abs_path, repo_root)
      repo_root = repo_root or git_utils.get_repo_root(vim.fn.dirname(abs_path))
      if not repo_root then
        return abs_path
      end
      
      -- Normalize paths and make relative
      local rel_path = vim.fn.fnamemodify(abs_path, ':.')
      if vim.startswith(rel_path, './') then
        rel_path = rel_path:sub(3)
      end
      return rel_path
    end
    
    -- Convert repo-relative path to absolute path
    function git_utils.to_absolute_path(rel_path, repo_root)
      repo_root = repo_root or git_utils.get_repo_root()
      if not repo_root then
        return rel_path
      end
      
      return repo_root .. '/' .. rel_path
    end

    -- Enhanced bookmark storage system
    local bookmarks_file = vim.fn.stdpath 'data' .. '/mini-files-bookmarks.lua'

    local load_bookmarks = function()
      local ok, bookmarks = pcall(dofile, bookmarks_file)
      if ok and type(bookmarks) == 'table' then
        -- Initialize structure if missing
        if not bookmarks.shortcuts then
          bookmarks.shortcuts = {}
        end
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
        shortcuts = {},
        git_bookmarks = {},
        global_bookmarks = {}
      }
    end

    local save_bookmarks = function(bookmarks)
      local file = io.open(bookmarks_file, 'w')
      if file then
        file:write('return ' .. vim.inspect(bookmarks))
        file:close()
      else
        vim.notify('Failed to save bookmarks to ' .. bookmarks_file, vim.log.levels.ERROR)
      end
    end

    local set_mark = function(id, path)
      MiniFiles.set_bookmark(id, path)
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

    -- Load appropriate bookmarks based on current context
    local load_context_bookmarks = function()
      local bookmarks = load_bookmarks()
      local context = get_current_context()
      
      if context.is_git_repo and context.remote_url then
        -- Load git-specific bookmarks
        local repo_bookmarks = bookmarks.git_bookmarks[context.remote_url] or {}
        local loaded = {}
        
        for id, mark in pairs(repo_bookmarks) do
          if mark.path then
            -- Convert relative paths to absolute for mini.files
            local abs_path = git_utils.to_absolute_path(mark.path, context.repo_root)
            -- mini.files bookmarks need directory paths, not file paths
            local bookmark_dir = vim.fn.isdirectory(abs_path) == 1 and abs_path or vim.fn.fnamemodify(abs_path, ':h')
            loaded[id] = { path = bookmark_dir, note = mark.note, file = mark.path }
            set_mark(id, bookmark_dir)
          end
        end
        
        vim.notify('Loaded ' .. vim.tbl_count(loaded) .. ' bookmarks for repo: ' .. (context.remote_url:match('([^/]+)%.git$') or context.remote_url), vim.log.levels.INFO)
        return loaded
      else
        -- Load global bookmarks
        local loaded = {}
        for id, mark in pairs(bookmarks.global_bookmarks) do
          if mark.path then
            -- mini.files bookmarks need directory paths, not file paths
            local bookmark_dir = vim.fn.isdirectory(mark.path) == 1 and mark.path or vim.fn.fnamemodify(mark.path, ':h')
            loaded[id] = { path = bookmark_dir, note = mark.note, file = mark.path }
            set_mark(id, bookmark_dir)
          end
        end
        
        vim.notify('Loaded ' .. vim.tbl_count(loaded) .. ' global bookmarks', vim.log.levels.INFO)
        return loaded
      end
    end

    -- Load bookmarks when mini.files explorer opens
    vim.api.nvim_create_autocmd('User', {
      pattern = 'MiniFilesExplorerOpen',
      callback = function()
        load_context_bookmarks()
      end,
    })

    -- Enhanced mini.files keybindings
    vim.api.nvim_create_autocmd('User', {
      pattern = 'MiniFilesBufferCreate',
      callback = function(args)
        local buf_id = args.data.buf_id

        -- Edit current context bookmarks
        vim.keymap.set('n', 'bm', function()
          MiniFiles.close()
          local context = get_current_context()
          local target_file
          
          if context.is_git_repo and context.remote_url then
            -- For now, edit the main bookmarks file
            -- TODO: Create repo-specific bookmark editing interface
            target_file = bookmarks_file
          else
            target_file = bookmarks_file
          end
          
          vim.cmd('edit ' .. target_file)
        end, { buffer = buf_id, desc = 'Edit bookmarks file' })
        
        -- Add current file to bookmarks
        vim.keymap.set('n', 'ma', function()
          local current_file = vim.api.nvim_buf_get_name(0)
          if current_file == '' then
            vim.notify('No file to bookmark', vim.log.levels.WARN)
            return
          end
          
          local context = get_current_context()
          local bookmarks = load_bookmarks()
          
          -- Use single character bookmark IDs for mini.files compatibility
          local bookmark_id = vim.fn.input('Bookmark ID (single character): ')
          
          if bookmark_id == '' or #bookmark_id ~= 1 then
            vim.notify('Bookmark ID must be a single character', vim.log.levels.WARN)
            return
          end
          
          local note = vim.fn.input('Note (optional): ')
          
          if context.is_git_repo and context.remote_url then
            -- Store as repo-relative bookmark
            local rel_path = git_utils.to_relative_path(current_file, context.repo_root)
            
            if not bookmarks.git_bookmarks[context.remote_url] then
              bookmarks.git_bookmarks[context.remote_url] = {}
            end
            
            bookmarks.git_bookmarks[context.remote_url][bookmark_id] = {
              path = rel_path,
              note = note ~= '' and note or nil
            }
            
            vim.notify('Added repo bookmark "' .. bookmark_id .. '" for ' .. rel_path, vim.log.levels.INFO)
          else
            -- Store as global bookmark
            bookmarks.global_bookmarks[bookmark_id] = {
              path = current_file,
              note = note ~= '' and note or nil
            }
            
            vim.notify('Added global bookmark "' .. bookmark_id .. '" for ' .. current_file, vim.log.levels.INFO)
          end
          
          save_bookmarks(bookmarks)
          load_context_bookmarks() -- Reload bookmarks
        end, { buffer = buf_id, desc = 'Add current file to bookmarks' })
        
        -- Quick folder shortcuts
        vim.keymap.set('n', '<leader>sa', function()
          local current_dir
          
          -- Get the actual filesystem path, not mini.files URI
          if vim.bo.filetype == 'minifiles' then
            local fs_entry = MiniFiles.get_fs_entry()
            if fs_entry then
              current_dir = vim.fn.isdirectory(fs_entry.path) == 1 and fs_entry.path or vim.fn.fnamemodify(fs_entry.path, ':h')
            else
              current_dir = vim.fn.getcwd()
            end
          else
            current_dir = vim.fn.getcwd()
          end
          
          -- Clean up any mini.files URI format
          if current_dir:match('^minifiles://') then
            -- Extract actual path from minifiles://48//path format
            current_dir = current_dir:gsub('^minifiles://%d+//', '')
          end
          
          local shortcut_name = vim.fn.input('Shortcut name for "' .. vim.fn.fnamemodify(current_dir, ':t') .. '": ')
          if shortcut_name == '' then
            return
          end
          
          local bookmarks = load_bookmarks()
          bookmarks.shortcuts[shortcut_name] = current_dir
          save_bookmarks(bookmarks)
          
          vim.notify('Added shortcut "' .. shortcut_name .. '" -> ' .. current_dir, vim.log.levels.INFO)
        end, { buffer = buf_id, desc = '[S]hortcut [A]dd current directory' })
        
        vim.keymap.set('n', '<leader>sj', function()
          local bookmarks = load_bookmarks()
          local shortcuts = {}
          
          for name, path in pairs(bookmarks.shortcuts) do
            table.insert(shortcuts, { name = name, path = path })
          end
          
          if #shortcuts == 0 then
            vim.notify('No shortcuts defined. Use <leader>sa to add one.', vim.log.levels.INFO)
            return
          end
          
          -- Create selection interface
          local selected = vim.fn.inputlist(vim.tbl_map(function(item)
            return item.name .. ' -> ' .. item.path
          end, shortcuts))
          
          if selected > 0 and selected <= #shortcuts then
            local shortcut = shortcuts[selected]
            MiniFiles.close()
            MiniFiles.open(shortcut.path)
            vim.notify('Jumped to shortcut: ' .. shortcut.name, vim.log.levels.INFO)
          end
        end, { buffer = buf_id, desc = '[S]hortcut [J]ump to directory' })
        
        vim.keymap.set('n', '<leader>sl', function()
          local bookmarks = load_bookmarks()
          local shortcuts = {}
          
          for name, path in pairs(bookmarks.shortcuts) do
            table.insert(shortcuts, { name = name, path = path })
          end
          
          if #shortcuts == 0 then
            vim.notify('No shortcuts defined', vim.log.levels.INFO)
            return
          end
          
          -- Display shortcuts in a temporary buffer
          local buf = vim.api.nvim_create_buf(false, true)
          local lines = { '# Folder Shortcuts', '' }
          
          for _, shortcut in ipairs(shortcuts) do
            table.insert(lines, shortcut.name .. ' -> ' .. shortcut.path)
          end
          
          vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
          vim.api.nvim_buf_set_option(buf, 'filetype', 'text')
          vim.api.nvim_buf_set_option(buf, 'modifiable', false)
          
          -- Show in a floating window
          local win = vim.api.nvim_open_win(buf, true, {
            relative = 'editor',
            width = 80,
            height = math.min(20, #shortcuts + 4),
            row = math.floor((vim.o.lines - 20) / 2),
            col = math.floor((vim.o.columns - 80) / 2),
            border = 'rounded',
            title = 'Folder Shortcuts',
          })
          
          -- Close on any key
          vim.keymap.set('n', '<CR>', '<Cmd>close<CR>', { buffer = buf, silent = true })
          vim.keymap.set('n', '<Esc>', '<Cmd>close<CR>', { buffer = buf, silent = true })
          vim.keymap.set('n', 'q', '<Cmd>close<CR>', { buffer = buf, silent = true })
        end, { buffer = buf_id, desc = '[S]hortcut [L]ist all shortcuts' })
        
        vim.keymap.set('n', '<leader>se', function()
          MiniFiles.close()
          vim.cmd('edit ' .. bookmarks_file)
        end, { buffer = buf_id, desc = '[S]hortcut [E]dit bookmarks file' })
        
        -- Quick jump to letter in mini.files
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
        end, { buffer = buf_id, desc = 'Jump to line starting with letter' })
        
        -- Jump to bookmarked file from directory bookmark
        vim.keymap.set('n', 'gf', function()
          local fs_entry = MiniFiles.get_fs_entry()
          if not fs_entry then
            return
          end
          
          -- Check if this directory has a bookmarked file
          local bookmarks = load_bookmarks()
          local context = get_current_context()
          local current_dir = fs_entry.path
          
          -- Look for bookmark that points to this directory
          local bookmarked_file = nil
          
          if context.is_git_repo and context.remote_url then
            local repo_bookmarks = bookmarks.git_bookmarks[context.remote_url] or {}
            for id, mark in pairs(repo_bookmarks) do
              local bookmark_dir = vim.fn.isdirectory(mark.path) == 1 and mark.path or vim.fn.fnamemodify(mark.path, ':h')
              if bookmark_dir == current_dir then
                bookmarked_file = mark.path
                break
              end
            end
          else
            for id, mark in pairs(bookmarks.global_bookmarks) do
              local bookmark_dir = vim.fn.isdirectory(mark.path) == 1 and mark.path or vim.fn.fnamemodify(mark.path, ':h')
              if bookmark_dir == current_dir then
                bookmarked_file = mark.path
                break
              end
            end
          end
          
          if bookmarked_file then
            -- Navigate to the specific file
            local target_file = context.is_git_repo and context.remote_url and 
              git_utils.to_absolute_path(bookmarked_file, context.repo_root) or 
              bookmarked_file
            
            -- Find and select the file in mini.files
            local filename = vim.fn.fnamemodify(target_file, ':t')
            local pattern = '^.......' .. filename
            local line = vim.fn.search(pattern, 'W')
            if line > 0 then
              vim.notify('Found bookmarked file: ' .. filename, vim.log.levels.INFO)
            else
              vim.notify('Bookmarked file not found in current view: ' .. filename, vim.log.levels.WARN)
            end
          else
            vim.notify('No bookmarked file in this directory', vim.log.levels.INFO)
          end
        end, { buffer = buf_id, desc = '[G]oto bookmarked [F]ile in directory' })
      end,
    })

    -- Global keybindings for shortcuts (work outside mini.files)
    vim.keymap.set('n', '<leader>sa', function()
      local current_dir = vim.fn.getcwd()
      local shortcut_name = vim.fn.input('Shortcut name for "' .. vim.fn.fnamemodify(current_dir, ':t') .. '": ')
      if shortcut_name == '' then
        return
      end
      
      local bookmarks = load_bookmarks()
      bookmarks.shortcuts[shortcut_name] = current_dir
      save_bookmarks(bookmarks)
      
      vim.notify('Added shortcut "' .. shortcut_name .. '" -> ' .. current_dir, vim.log.levels.INFO)
    end, { desc = '[S]hortcut [A]dd current directory' })
    

    
    -- Enhanced telescope integration for shortcuts (git-aware)
    vim.keymap.set('n', '<leader>sj', function()
      local bookmarks = load_bookmarks()
      local context = get_current_context()
      local shortcuts = {}
      
      -- Add global shortcuts
      for name, path in pairs(bookmarks.shortcuts) do
        table.insert(shortcuts, {
          name = name,
          path = path,
          type = 'global',
          display = name .. ' -> ' .. path
        })
      end
      
      -- Add git repo bookmarks as shortcuts too!
      if context.is_git_repo and context.remote_url then
        local repo_bookmarks = bookmarks.git_bookmarks[context.remote_url] or {}
        for id, mark in pairs(repo_bookmarks) do
          if mark.path then
            local abs_path = git_utils.to_absolute_path(mark.path, context.repo_root)
            local display_name = id .. ' -> ' .. (mark.note or mark.path)
            table.insert(shortcuts, {
              name = id,
              path = abs_path,
              type = 'repo',
              display = display_name,
              note = mark.note
            })
          end
        end
      end
      
      if #shortcuts == 0 then
        vim.notify('No shortcuts or bookmarks defined. Use <leader>sa to add shortcuts or ma to add bookmarks.', vim.log.levels.INFO)
        return
      end
      
      -- Use telescope if available, otherwise fallback to inputlist
      local ok, telescope = pcall(require, 'telescope')
      if ok then
        local pickers = require('telescope.pickers')
        local finders = require('telescope.finders')
        local conf = require('telescope.config').values
        local actions = require('telescope.actions')
        local action_state = require('telescope.actions.state')
        
        pickers.new({}, {
          prompt_title = 'Shortcuts & Bookmarks',
          finder = finders.new_table({
            results = shortcuts,
            entry_maker = function(entry)
              return {
                value = entry,
                display = entry.display,
                ordinal = entry.name .. ' ' .. entry.path
              }
            end
          }),
          sorter = conf.generic_sorter({}),
          attach_mappings = function(prompt_bufnr, map)
            actions.select_default:replace(function()
              actions.close(prompt_bufnr)
              local selection = action_state.get_selected_entry()
              if selection then
                if selection.value.type == 'repo' then
                  -- For repo bookmarks, open to directory and navigate to file
                  local dir = vim.fn.fnamemodify(selection.value.path, ':h')
                  MiniFiles.open(dir)
                  vim.schedule(function()
                    -- Find and select the file
                    local filename = vim.fn.fnamemodify(selection.value.path, ':t')
                    local pattern = '^.......' .. filename
                    vim.fn.search(pattern, 'W')
                  end)
                  vim.notify('Jumped to repo bookmark: ' .. selection.value.name, vim.log.levels.INFO)
                else
                  -- For global shortcuts, open directly
                  MiniFiles.open(selection.value.path)
                  vim.notify('Jumped to shortcut: ' .. selection.value.name, vim.log.levels.INFO)
                end
              end
            end)
            return true
          end,
        }):find()
      else
        -- Fallback to inputlist if telescope not available
        local selected = vim.fn.inputlist(vim.tbl_map(function(item)
          return item.display
        end, shortcuts))
        
        if selected > 0 and selected <= #shortcuts then
          local shortcut = shortcuts[selected]
          if shortcut.type == 'repo' then
            local dir = vim.fn.fnamemodify(shortcut.path, ':h')
            MiniFiles.open(dir)
            vim.schedule(function()
              local filename = vim.fn.fnamemodify(shortcut.path, ':t')
              local pattern = '^.......' .. filename
              vim.fn.search(pattern, 'W')
            end)
            vim.notify('Jumped to repo bookmark: ' .. shortcut.name, vim.log.levels.INFO)
          else
            MiniFiles.open(shortcut.path)
            vim.notify('Jumped to shortcut: ' .. shortcut.name, vim.log.levels.INFO)
          end
        end
      end
    end, { desc = '[S]hortcut [J]ump with telescope (includes repo bookmarks)' })

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