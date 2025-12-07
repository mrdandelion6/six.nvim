# config files

here is a breakdown of the files in my config and what they are for.

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

note that `to_try/` contains configuration from the originally forked **kickstart.nvim** that i'm not using yet but intending to check out in the future.

## lua/core/

here's a list of files that are in `lua/core/`:

### autocmds.lua

Sets up Neovim autocommands and utility functions:

- **netrw key fix** - removes `<C-l>` mapping from netrw so it doesn't conflict with window navigation
- **yank highlighting** - briefly highlights text when copying
- **git root tracking** - automatically detects and stores the current git repository name in `vim.g.git_root`
- **disable formatting command** - adds `:DisableFormatting` to turn off LSP auto-formatting for the current buffer
- **always center cursor** - keeps the cursor vertically centered in the window during navigation

### cmds.lua

defines custom neovim commands:

- **Vr** - shorthand for vertical resize: `:Vr 80` instead of `:vertical resize 80`
- **Ww** - write file without triggering auto-formatting

### keymaps.lua

handles keyboard layout switching and key mappings:

- **layout switching** - toggles between qwerty and colemak-dh layouts with `:ToggleColemak` or `<leader>tc`
- **colemak remapping** - maps `knei` to `hjkl` for navigation, with comprehensive key remapping across all modes
- **buffer jumping** - bets `<C-hjkl>` or `<C-knei>` for window navigation depending on active layout
- **plugin integration** - updates telescope and vim-visual-multi keybinds based on current layout
- **layout persistence** - saves current layout to `.localsettings.json` to remember preference across sessions
- **message utilities** - `<leader>mm` to copy recent message, `<leader>mn` to open messages in new buffer
- **yank modifications** - disables yanking for change operations (`c`, `C`) and delete key
- **general bindings** - `<Esc>` clears search highlights, `<leader>q` opens diagnostics, terminal mode escape

see [here](../readme.md#colemak-swappable) for more.

### lazy.lua

bootstrap module for the lazy.nvim plugin manager:

- **auto-installation** - automatically clones and installs lazy.nvim if not present
- **path setup** - adds lazy.nvim to neovim's runtime path
- **error handling** - shows git clone errors if bootstrap fails
- **usage notes** - use `:Lazy` to check plugin status, `:Lazy update` to update plugins

### options.lua

core neovim configuration and settings:

- **basic ui** - line numbers (absolute + relative), mouse support, no mode display, cursor line highlighting
- **clipboard** - syncs with system clipboard (scheduled after ui loads for faster startup)
- **indentation** - 4-space tabs, smart indenting, break indent for wrapped lines
- **editor behavior** - undo history persistence, fast update times, smart splits
- **visual elements** - whitespace characters display, custom fill characters for splits, global status bar
- **scrolling** - always centers cursor (`scrolloff = 999`)
- **local settings** - loads `.localsettings.json` for user preferences, auto-generates from template if missing
- **python integration** - sets virtual environment path for neovim python dependencies
- **platform setup** - calls platform-specific startup configuration

### platform.lua

cross-platform utilities and platform detection:

- **platform detection** - automatically detects windows, macos, or linux
- **file operations** - `cp()` and `mv()` functions that work across platforms with proper path escaping
- **shell configuration** - sets powershell as default on windows, keeps bash on unix systems
- **path handling** - platform-specific path escaping (powershell vs unix shell compatibility)
- **startup integration** - called by options.lua to apply platform-specific settings

### ui.lua

sets custom emoji icons for lazy plugin manager interface when nerd fonts aren't available.

### utils.lua

utility functions for common operations:

- **deep copy** - recursively copies tables including metatables
- **markdown mode** - detects if in special markdown mode (firenvim or md_mode environment)
- **message copying** - press `<leader>mm` to use copy the most recent neovim message to clipboard or `<leader>mn` to open a buffer with all messages.

## lua/plugins/

too many.. lazy to explain them. maybe one day when i'm not so lazy i will.

## non-config

these files are not part of the lua configuration for neovim but may help with other things.

### bashrc.sh

copy this into your `~/.bashrc` for features like [Terminal Buffers Keep Title as PWD](../README.md#termnal-title).
