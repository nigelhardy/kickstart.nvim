return {
    {
        "github/copilot.vim",
        cond = false,
    },
    {
        "olimorris/codecompanion.nvim",
        version = "^18.0.0",
        opts = {},
        dependencies = {
            "nvim-lua/plenary.nvim",
            "nvim-treesitter/nvim-treesitter",
        },
    },
}

