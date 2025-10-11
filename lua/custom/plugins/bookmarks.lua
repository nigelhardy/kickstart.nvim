-- with lazy.nvim
return {
  'LintaoAmons/bookmarks.nvim',
  -- pin the plugin at specific version for stability
  -- backup your bookmark sqlite db when there are breaking changes (major version change)
  tag = '3.2.0',
  dependencies = {
    { 'kkharji/sqlite.lua' },
    { 'nvim-telescope/telescope.nvim' }, -- currently has only telescopes supported, but PRs for other pickers are welcome
    { 'stevearc/dressing.nvim' }, -- optional: better UI
    { 'GeorgesAlkhouri/nvim-aider' }, -- optional: for Aider integration
  },
  init = function()
    -- I have to point this thing to the SQLite3 DLL manually on Windows.
    -- Downloads here: https://www.sqlite.org/download.html
    -- Choose the "Precompiled Binaries for Windows" option.
    if vim.loop.os_uname().sysname == 'Windows_NT' then
      vim.g.sqlite_clib_path = vim.fs.normalize '~/sqlite3.dll'
    end
  end,
  config = function()
    local opts = {} -- check the "./lua/bookmarks/default-config.lua" file for all the options
    require('bookmarks').setup(opts) -- you must call setup to init sqlite db
  end,
}
