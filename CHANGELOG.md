# Change Log

### v2.0
- **Jupyter notebooks & code execution**: Major feature addition - execute code cells in `.ipynb` , `.md` , and `.qmd` files using Jupyter kernels via `molten.nvim` and `quarto.nvim`. Navigate cells with `]]`/`[[` , run with `<leader>rc`. Currently Linux-only.
- **Treesitter text objects**: Added custom text objects for markdown code cells - select with `ac`/`ic` , jump between cells , and navigate functions
- **Formatting system overhaul**: Unified formatting with LSP and Conform integration. Toggle per-buffer formatting with `<leader>tf`
- **Improved performance**: Replaced `vim.fn.system()` with `vim.system()` for Git operations , eliminating shell profile invocations and significantly reducing lag
- **CSV rendering**: Added `csvview.nvim` for readable CSV display with automatic view toggling
- **Documentation refactor**: Reorganized setup guides and added comprehensive notebooks documentation
- **Plugin cleanup**: Removed `mini.nvim` , fixed various keybinding conflicts , improved Oil.nvim integration
- **LaTeX snippets**: Expanded snippet collection with proof environments , math commands , and custom macros
- **Bug fixes**: Fixed autoformatting on new buffers , Clangd arguments , CSV navigation conflicts , and Stylua LSP false positives

### v1.3
- **Restructured plugin files**: Refactored all plugin code into files with accuarate naming. Created subdirectories under `lua/plugins/` for better organization.
- **Debug support**: Finally added debugging support with `nvim-dap` for C/C++ , Python , and Bash. This is a major feature I've been looking into.
- **Oil.nvim**: Now using `oil.nvim` for quick file creation and deletion.

### v1.2
- **LaTeX compilation support**: Added LaTeX support with automatic compilation and hot reloading using `vimtex` plugin
- **Git root caching**: Now caching Git root directory paths to reduce calls for `git -C %s rev-parse --show-toplevel` as this caused lag issues on Windows devices

### v1.1
- **Terminal title updates**: Resolved plugin loading order issue that prevented terminal titles from updating properly
- **Discord presence**: Added Discord presence using `presence.nvim`

### v1.0
- **Renamed to six.nvim**: Updated branding and reached version 1.0 milestone
- Cursor automatically centers when text changes (undo, edits, etc.) for better focus now
- Fixed EOF cursor positioning bug and improved save behavior with cursor centering
- **Added documentation**: Added Windows setup guide alongside existing Arch and Ubuntu documentation
