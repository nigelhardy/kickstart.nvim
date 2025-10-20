# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Project Overview

This is a **kickstart.nvim** configuration - a single-file Neovim starter configuration designed to be read, understood, and modified by the user. It's not a distribution but a teaching tool and foundation for personal Neovim setups.

Key characteristics:
- Single `init.lua` file with extensive documentation
- Uses `lazy.nvim` as plugin manager
- Includes LSP, completion, formatting, and fuzzy finding
- Modular plugin system via `lua/custom/plugins/` and `lua/kickstart/plugins/`

## Common Commands

### Core Neovim Operations
- **Start Neovim**: `nvim`
- **Run Neovim tutorial**: `:Tutor` (first-time users should do this)
- **Check health**: `:checkhealth` (diagnose configuration issues)
- **Update plugins**: `:Lazy update`
- **View plugin status**: `:Lazy`
- **Format current buffer**: `<leader>f` (space + f)

### Lua Formatting
- **Format Lua code**: Uses `stylua` with configuration in `.stylua.toml`
- **Manual format**: `stylua init.lua` or `stylua lua/`

### Plugin Management
- **Add new plugins**: Edit `lua/custom/plugins/init.lua` or create new files in `lua/custom/plugins/`
- **Lazy load plugins**: Configure with `event`, `cmd`, or `keys` in plugin spec
- **Plugin help**: `<space>sh` then search for plugin name

### Key Mappings Reference
- **Leader key**: `<space>` (spacebar)
- **Search help**: `<space>sh`
- **Search files**: `<space>sf` or `<space>ff`
- **Live grep**: `<space>sg` or `<space>fg`
- **Search keymaps**: `<space>sk`
- **File tree**: `\` (backslash) to toggle Neo-tree
- **Buffer search**: `<space><space>`
- **Bookmarks**: `mm` (mark), `mo` (goto), `ma` (commands)

### LSP Operations
- **Go to definition**: `grd`
- **Go to references**: `grr` 
- **Go to implementation**: `gri`
- **Rename symbol**: `grn`
- **Code actions**: `gra`
- **Toggle inlay hints**: `<space>th`
- **Document symbols**: `gO`
- **Workspace symbols**: `gW`

## Architecture Overview

### Plugin Management System
- **Lazy.nvim**: Plugin manager with lazy loading capabilities
- **Mason**: LSP server, DAP server, linter, and formatter installer
- **Plugin organization**: 
  - Core plugins defined in main `init.lua`
  - Custom plugins in `lua/custom/plugins/`
  - Kickstart example plugins in `lua/kickstart/plugins/`

### LSP Architecture
- **nvim-lspconfig**: Core LSP client configuration
- **Mason integration**: Automatic tool installation
- **Blink.cmp**: Modern completion engine with LSP integration
- **Language servers**: Configured in `servers` table in init.lua
- **Capabilities**: Enhanced by completion engine for better LSP features

### Plugin Categories
1. **Core functionality**: Treesitter (syntax), LSP (language features), Telescope (fuzzy finding)
2. **UI enhancements**: Which-key (keybind help), Mini.nvim modules, colorscheme
3. **Development tools**: Gitsigns, formatting (conform.nvim), completion (blink.cmp)
4. **Custom additions**: Bookmarks, file trees, git integration (neogit)

### File Structure
```
nvim/
├── init.lua              # Main configuration file (read this first!)
├── lua/
│   ├── custom/
│   │   └── plugins/      # Your custom plugin configurations
│   └── kickstart/
│       └── plugins/      # Example plugin configurations
├── .stylua.toml          # Lua formatter configuration
└── .gitignore           # Git ignore patterns
```

### Custom Plugin Extensions
Current custom plugins include:
- **Bookmarks**: Line bookmarking with SQLite backend
- **Clangd**: Enhanced C/C++ language server configuration
- **Neogit**: Git interface within Neovim
- **Gruvbox**: Alternative colorscheme option
- **Nvim-tree**: File explorer (alternative to Neo-tree)

## Development Workflow

### Adding New Languages
1. Add language server to `servers` table in init.lua
2. Update `ensure_installed` in mason-tool-installer setup
3. Configure formatters in `formatters_by_ft` table
4. Add Treesitter parser to `ensure_installed`

### Plugin Development Pattern
- Create new file in `lua/custom/plugins/` 
- Return plugin specification table
- Use lazy loading with `event`, `cmd`, or `keys`
- Configure with `opts` table or `config` function

### Testing Changes
1. Restart Neovim to load new configuration
2. Run `:checkhealth` to verify setup
3. Use `:Lazy` to check plugin status
4. Test LSP with `:LspInfo` for language-specific changes

### Windows-Specific Notes
- SQLite3 DLL must be manually configured for bookmarks plugin
- Uses PowerShell as default shell
- File paths use Windows backslash format
- Configuration location: `$env:LOCALAPPDATA\nvim\`

## Important Conventions

### Configuration Philosophy
- **Single-file approach**: Main config in init.lua for readability
- **Extensive comments**: Every section explained for learning
- **Modular extensions**: Custom plugins in separate files
- **Lazy loading**: Plugins load only when needed for performance

### Keymap Patterns
- `<leader>s*`: Search operations (space + s + key)
- `<leader>t*`: Toggle operations (space + t + key)
- `gr*`: LSP "go to" operations (gr + key)
- `<leader>f*`: File/format operations (space + f + key)

### Plugin Configuration Style
- Use `opts = {}` for simple setup() calls
- Use `config = function()` for complex configuration
- Specify dependencies explicitly
- Use semantic versioning where possible