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

#### Phase 2: Git-Remote Detection and Storage ✅
- [x] Implement git repository detection using `git rev-parse --show-toplevel`
- [x] Extract remote URL: `git remote get-url origin` (or primary remote)
- [x] Create storage structure keyed by remote URL for repo portability
- [x] Implement path normalization (absolute ↔ relative within repo)
- [x] Fallback chain: remote URL → repo path → global bookmarks

#### Phase 3: Quick Folder Shortcuts System ✅
- [x] Add global shortcuts storage for frequently accessed directories
- [x] Implement keybinding system: `<leader>sa` (add), `<leader>sj` (jump), `<leader>sl` (list), `<leader>se` (edit)
- [x] Create mini.files integration for direct opening to shortcuts
- [x] Add telescope integration for fuzzy finding shortcuts
- [x] Fix keybinding conflict - restored original <leader>sf for file search, moved shortcuts to <leader>sj
- [x] Fix mini.files URI path detection - ensure shortcuts store actual filesystem paths
- [x] Fix git remote URL matching - update bookmarks to use actual repo remote format
- [x] Fix g/ letter jump - move to correct MiniFilesBufferCreate autocmd
- [x] Fix mini.files bookmark ID format - use single characters as required by mini.files
- [x] Fix mini.files bookmark path format - use directory paths instead of file paths
- [x] Add gf keybinding to jump to bookmarked file from directory bookmark
- [x] Make shortcuts git-aware - <leader>sj now includes both global shortcuts AND repo bookmarks

** g/ seems broken for ~/ directory might be capital letters, or depth, or . files
Need to clean up and make it intuitive to add relative paths for a repo, and also global paths
I want for work each controller folder to be easy to fuzzy find without trouble and open in mini files
maybe I just add to <leader>sf a way to open in mini.files
bookmarks need cleaning and the way mini.files folder bookmarks are single char keys, and others are full names

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
