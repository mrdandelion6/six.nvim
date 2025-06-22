# Config Files
Here is a breakdown of the files in my config and what they are for.

```
lua/
├── core/
│   ├── autocmds.lua
│   ├── cmds.lua
│   ├── keymaps.lua
│   ├── lazy.lua
│   ├── options.lua
│   ├── platform.lua
│   ├── ui.lua
│   └── utils.lua
├── plugins/
│   └── ...
└── to_try/
```
Note that `to_try/` contains configuration from the originally forked **kickstart.nvim** that I'm not using yet but intending to check out in the future.

## Lua/Core/
Here's a list of files that are in `lua/core/`:

### autocmds.lua
Sets up Neovim autocommands and utility functions:
- **Netrw key fix** - Removes `<C-l>` mapping from netrw so it doesn't conflict with window navigation
- **Yank highlighting** - Briefly highlights text when copying
- **Git root tracking** - Automatically detects and stores the current git repository name in `vim.g.git_root`
- **Disable formatting command** - Adds `:DisableFormatting` to turn off LSP auto-formatting for the current buffer
- **Always center cursor** - Keeps the cursor vertically centered in the window during navigation

### cmds.lua
Defines custom Neovim commands:
- **Vr** - Shorthand for vertical resize: `:Vr 80` instead of `:vertical resize 80`
- **Ww** - Write file without triggering auto-formatting

### keymaps.lua
Handles keyboard layout switching and key mappings:
- **Layout switching** - Toggles between QWERTY and Colemak-DH layouts with `:ToggleColemak` or `<leader>tc`
- **Colemak remapping** - Maps `knei` to `hjkl` for navigation, with comprehensive key remapping across all modes
- **Buffer jumping** - Sets `<C-hjkl>` or `<C-knei>` for window navigation depending on active layout
- **Plugin integration** - Updates Telescope and vim-visual-multi keybinds based on current layout
- **Layout persistence** - Saves current layout to `.localsettings.json` to remember preference across sessions
- **Message utilities** - `<leader>mm` to copy recent message, `<leader>mn` to open messages in new buffer
- **Yank modifications** - Disables yanking for change operations (`c`, `C`) and delete key
- **General bindings** - `<Esc>` clears search highlights, `<leader>q` opens diagnostics, terminal mode escape
See [here](../README.md#colemak-swappable) for more.

### lazy.lua
Bootstrap module for the Lazy.nvim plugin manager:
- **Auto-installation** - Automatically clones and installs Lazy.nvim if not present
- **Path setup** - Adds Lazy.nvim to Neovim's runtime path
- **Error handling** - Shows git clone errors if bootstrap fails
- **Usage notes** - Use `:Lazy` to check plugin status, `:Lazy update` to update plugins

### options.lua
Core Neovim configuration and settings:
- **Basic UI** - Line numbers (absolute + relative), mouse support, no mode display, cursor line highlighting
- **Clipboard** - Syncs with system clipboard (scheduled after UI loads for faster startup)
- **Indentation** - 4-space tabs, smart indenting, break indent for wrapped lines
- **Editor behavior** - Undo history persistence, fast update times, smart splits
- **Visual elements** - Whitespace characters display, custom fill characters for splits, global status bar
- **Scrolling** - Always centers cursor (`scrolloff = 999`)
- **Local settings** - Loads `.localsettings.json` for user preferences, auto-generates from template if missing
- **Python integration** - Sets virtual environment path for Neovim Python dependencies
- **Platform setup** - Calls platform-specific startup configuration

### platform.lua
Cross-platform utilities and platform detection:
- **Platform detection** - Automatically detects Windows, macOS, or Linux
- **File operations** - `cp()` and `mv()` functions that work across platforms with proper path escaping
- **Shell configuration** - Sets PowerShell as default on Windows, keeps bash on Unix systems
- **Path handling** - Platform-specific path escaping (PowerShell vs Unix shell compatibility)
- **Startup integration** - Called by options.lua to apply platform-specific settings

### ui.lua
Sets custom emoji icons for Lazy plugin manager interface when Nerd Fonts aren't available.

### utils.lua
Utility functions for common operations:
- **Deep copy** - Recursively copies tables including metatables
- **Markdown mode** - Detects if in special markdown mode (Firenvim or MD_MODE environment)
- **Message copying** - Press `<leader>mm` to use copy the most recent Neovim message to clipboard or `<leader>mn` to open a buffer with all messages.

## Lua/Plugins/
Too many.. lazy to explain them all. Here's a list of them:
```
- autosession.lua
- coding.lua
- colorscheme.lua
- comments.lua
- editor.lua
- git.lua
- images.lua.unstable
- init.lua
- lsp.lua
- multicursor.lua
- quarto.lua.unstable
- render.lua.unstable
- repl.lua.unstable
- statusline.lua
- telescope.lua
- utils.lua
```
Maybe one day when I'm not so lazy I will explain them all.

## Non-config
These files are not part of the lua configuration for Neovim but may help with other things.

### bashrc.sh
Copy this into your `~/.bashrc` for features like [Terminal Buffers Keep Title as PWD](../README.md#termnal-title).
