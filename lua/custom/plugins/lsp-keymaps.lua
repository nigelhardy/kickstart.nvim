-- Additional LSP keymaps beyond the defaults in init.lua
-- These are organized under <leader>l for easy discovery

return {
  'neovim/nvim-lspconfig',
  opts = function()
    -- This function runs when nvim-lspconfig is being configured
    -- We'll add our keymaps to the LspAttach autocmd
    vim.api.nvim_create_autocmd('LspAttach', {
      group = vim.api.nvim_create_augroup('custom-lsp-keymaps', { clear = true }),
      callback = function(event)
        local map = function(keys, func, desc, mode)
          mode = mode or 'n'
          vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
        end

        -- Show variables and constants in current document
        map('<leader>lv', function()
          require('telescope.builtin').lsp_document_symbols({
            symbols = { 'variable', 'constant' }
          })
        end, 'Find [V]ariables in file')

        -- Show functions and methods in current document
        map('<leader>lf', function()
          require('telescope.builtin').lsp_document_symbols({
            symbols = { 'function', 'method' }
          })
        end, 'Find [F]unctions in file')

        -- Show all document symbols
        map('<leader>ls', require('telescope.builtin').lsp_document_symbols, 'Document [S]ymbols')

        -- Workspace-wide symbol search
        map('<leader>lw', require('telescope.builtin').lsp_workspace_symbols, '[W]orkspace symbols')
        map('<leader>lW', require('telescope.builtin').lsp_dynamic_workspace_symbols, 'Dynamic [W]orkspace symbols')

        -- Call hierarchy
        map('<leader>lci', require('telescope.builtin').lsp_incoming_calls, 'Incoming [C]alls')
        map('<leader>lco', require('telescope.builtin').lsp_outgoing_calls, 'Outgoing [C]alls')

        -- Diagnostics (errors/warnings)
        map('<leader>le', require('telescope.builtin').diagnostics, 'Show [E]rrors/diagnostics')
        map('<leader>lE', function()
          require('telescope.builtin').diagnostics({ bufnr = 0 })
        end, 'Buffer [E]rrors/diagnostics')

        -- Hover documentation
        map('K', vim.lsp.buf.hover, 'Hover documentation')

        -- Signature help
        map('<leader>lh', vim.lsp.buf.signature_help, 'Signature [H]elp')
        map('<C-k>', vim.lsp.buf.signature_help, 'Signature help', 'i')

        -- Switch between source and header files (clangd specific)
        map('<leader>lp', '<cmd>LspClangdSwitchSourceHeader<cr>', 'Switch between source/header')

        -- Toggle LSP on/off for current buffer
        map('<leader>tl', function()
          local buf = event.buf
          local clients = vim.lsp.get_clients { bufnr = buf }
          local lsp_state = vim.b[buf].lsp_enabled

          -- Initialize state if not set
          if lsp_state == nil then
            lsp_state = #clients > 0
            vim.b[buf].lsp_enabled = lsp_state
          end

          if lsp_state then
            -- Disable LSP for this buffer
            for _, client in ipairs(clients) do
              vim.lsp.buf_detach_client(buf, client.id)
            end
            vim.b[buf].lsp_enabled = false
            vim.notify('LSP disabled for buffer', vim.log.levels.INFO)
          else
            -- Re-enable LSP by triggering filetype detection, which preserves unsaved changes
            vim.b[buf].lsp_enabled = true
            vim.notify('Re-enabling LSP for buffer...', vim.log.levels.INFO)
            
            -- Trigger filetype detection to re-attach LSP without losing changes
            vim.cmd('filetype detect')
          end
        end, '[T]oggle [L]SP')

      end,
    })
  end,
}
