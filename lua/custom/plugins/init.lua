-- You can add your own plugins here or in other files in this directory!
--  I promise not to create any merge conflicts in this directory :)
--
-- See the kickstart.nvim README for more information
return {
  -- Primary colorscheme
  {
    'folke/tokyonight.nvim',
    lazy = false, -- Load at startup to avoid flash
    priority = 1000, -- Highest priority to load first
    init = function()
      -- Load colorscheme immediately to avoid startup delay
      vim.cmd.colorscheme 'tokyonight-night'

      -- Make background transparent
      vim.cmd [[
        highlight Normal guibg=NONE ctermbg=NONE
        highlight NormalNC guibg=NONE ctermbg=NONE
        highlight SignColumn guibg=NONE ctermbg=NONE
        highlight EndOfBuffer guibg=NONE ctermbg=NONE
      ]]
    end,
    opts = {
      transparent = true,
      styles = {
        comments = { italic = false }, -- Disable italics in comments
        sidebars = 'transparent',
        floats = 'transparent',
      },
    },
  },

  -- Alternative colorscheme (lazy loaded)
  {
    'ellisonleao/gruvbox.nvim',
    priority = 1000,
    lazy = true, -- Only load if explicitly switched to
  },
}
