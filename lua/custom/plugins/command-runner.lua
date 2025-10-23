-- Custom command runner using Telescope
return {
  {
    'nvim-telescope/telescope.nvim',
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = function()
      -- Your existing telescope config is in init.lua, so we'll just add the custom picker
      
      local pickers = require('telescope.pickers')
      local finders = require('telescope.finders')
      local conf = require('telescope.config').values
      local actions = require('telescope.actions')
      local action_state = require('telescope.actions.state')

      -- Define your PowerShell commands here
      local commands = {
        { name = "blvlp Build LV Controller Launchpad", cmd = "build-lvlp" },
        { name = "blvcc Build LV Control Card", cmd = "build-lvcc" },
        { name = "flv1lp Flash LV1 Control Card", cmd = "flash-lv1cc" },
        { name = "flv1cc Flash LV1 Control Card", cmd = "flash-lv1cc" },
        { name = "fmv1lp Flash MV1 Control Card", cmd = "flash-mv1lp" },
        { name = "fmv1cc Flash MV1 Control Card", cmd = "flash-mv1cc" },
        { name = "bmvlp Build MV Control Card", cmd = "build-mvlp" },
        { name = "bmvcc Build MV Control Card", cmd = "build-mvcc" },
      }

      local function run_command_picker()
        pickers.new({}, {
          prompt_title = "PowerShell Commands",
          finder = finders.new_table({
            results = commands,
            entry_maker = function(entry)
              return {
                value = entry,
                display = entry.name,
                ordinal = entry.name,
              }
            end,
          }),
          sorter = conf.generic_sorter({}),
          attach_mappings = function(prompt_bufnr, map)
            actions.select_default:replace(function()
              actions.close(prompt_bufnr)
              local selection = action_state.get_selected_entry()
              local cmd = selection.value.cmd
              
              -- Run the PowerShell command and show output in a new buffer
              vim.cmd('botright new')
              local buf = vim.api.nvim_get_current_buf()
              vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
              vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
              vim.api.nvim_buf_set_name(buf, 'Command Output: ' .. selection.value.name)
              
              -- Execute the command and capture output (with profile loaded)
              local full_cmd = 'pwsh -Command "' .. cmd .. '"'
              local output = vim.fn.systemlist(full_cmd)
              
              -- Display the output in the buffer
              vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
                '=== Command: ' .. selection.value.name .. ' ===',
                '=== Full Command: ' .. full_cmd .. ' ===',
                '',
              })
              vim.api.nvim_buf_set_lines(buf, -1, -1, false, output)
              
              -- Set buffer as read-only
              vim.api.nvim_buf_set_option(buf, 'readonly', true)
              vim.api.nvim_buf_set_option(buf, 'modifiable', false)
              
              -- Set filetype for syntax highlighting if needed
              vim.api.nvim_buf_set_option(buf, 'filetype', 'text')
            end)
            return true
          end,
        }):find()
      end

      -- Create the keymap
      vim.keymap.set('n', '<leader>cr', run_command_picker, { desc = '[C]ommand [R]unner' })
    end,
  }
}
