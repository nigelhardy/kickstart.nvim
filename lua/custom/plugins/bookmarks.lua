-- with lazy.nvim
return {
  'LintaoAmons/bookmarks.nvim',
  tag = '3.2.0',
  cmd = { 'BookmarksMark', 'BookmarksGoto', 'BookmarksCommands', 'BookmarksList' },
  keys = {
    { 'mm', '<cmd>BookmarksMark<cr>', desc = 'Mark current line into active BookmarkList', mode = { 'n', 'v' } },
    { 'mo', '<cmd>BookmarksGoto<cr>', desc = 'Go to bookmark at current active BookmarkList', mode = { 'n', 'v' } },
    { 'ma', '<cmd>BookmarksCommands<cr>', desc = 'Find and trigger a bookmark command', mode = { 'n', 'v' } },
  },
  dependencies = {
    { 'kkharji/sqlite.lua' },
    { 'nvim-telescope/telescope.nvim' },
    { 'stevearc/dressing.nvim' },
    -- { 'GeorgesAlkhouri/nvim-aider' }, -- not using Aider, so not added
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
