## Next Steps and Additions Desired

1. <leader>p to paste and not lose the register

## Git-Aware Mini.files Bookmarks Project

### Overview
Refactor mini.files bookmark system to be git-repository aware with remote URL keying and quick folder shortcuts.

### Phases

#### Phase 1: Extract Current Bookmark System ✅
- [x] Extract mini.files bookmark code from init.lua (lines 894-936) into new plugin file
- [x] Create `lua/custom/plugins/mini-files.lua` with all mini.nvim configuration
- [x] Maintain existing functionality while modularizing
- [x] Update init.lua to remove mini.nvim configuration (now in separate file)

#### Phase 2: Git-Remote Detection and Storage
- [ ] Implement git repository detection using `git rev-parse --show-toplevel`
- [ ] Extract remote URL: `git remote get-url origin` (or primary remote)
- [ ] Create storage structure keyed by remote URL for repo portability
- [ ] Implement path normalization (absolute ↔ relative within repo)
- [ ] Fallback chain: remote URL → repo path → global bookmarks

#### Phase 3: Quick Folder Shortcuts System
- [ ] Add global shortcuts storage for frequently accessed directories
- [ ] Implement keybinding system: `<leader>sa` (add), `<leader>sj` (jump), `<leader>sl` (list), `<leader>se` (edit)
- [ ] Create mini.files integration for direct opening to shortcuts
- [ ] Add telescope integration for fuzzy finding shortcuts

#### Phase 4: Unified Storage Architecture
- [ ] Design combined storage structure for shortcuts, git bookmarks, and global bookmarks
- [ ] Implement bookmark commands for repo-specific vs global bookmarks
- [ ] Create migration path for existing global bookmarks
- [ ] Add bookmark switching when changing directories

#### Phase 5: Enhanced Integration and Testing
- [ ] Update mini.files configuration to use the new git-aware bookmark system
- [ ] Test across different git repositories and clones
- [ ] Verify fallback behavior for non-git directories
- [ ] Ensure all existing keybindings continue to work

### Proposed Storage Structure
```lua
{
  shortcuts = {
    ["config"] = "/Users/nigel/.config/nvim",
    ["projects"] = "/Users/nigel/projects"
  },
  git_bookmarks = {
    ["https://github.com/user/repo.git"] = {
      bookmarks = {
        ["src/main.lua"] = { line = 42, note = "Main entry point" }
      }
    }
  },
  global_bookmarks = {
    ["/some/path/file.txt"] = { line = 10 }
  }
}
```

### Key Benefits
- **Repo Portability**: Same bookmarks work in any clone of the repo
- **Quick Navigation**: Fast folder bouncing with shortcuts
- **Context Awareness**: Automatic repo/global bookmark switching
- **Backward Compatibility**: Existing bookmarks preserved
