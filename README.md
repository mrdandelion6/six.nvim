# six.nvim ![Version](https://img.shields.io/badge/version-2.0-blue)

Welcome to my custom configuration for Neovim. This configuration was originally forked from **kickstart.nvim** but has been greatly changed.

![Screenshot](samples/nvim.png)

## Latest Changes
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

See more in [CHANGELOG.md](CHANGELOG.md)

## Setup
You will generally need the following dependencies installed and on PATH:
- curl
- unzip
- python
- python-pip
- nodejs
- npm
- ripgrep

For more **specific set up instructions** depending on your OS and distribution , see the guides inside `doc/`:
- [Ubuntu/Debian](doc/linux/ubuntu/setup.md)
- [Windows](doc/windows/setup.md)
- [Arch](doc/linux/arch/setup.md)

## Key Features
This is an all purpose configuration with a focus on coding in many different programming languages. Below is an overview of some key features of my config. I plan on making separate plugins for all of these eventually.

<a id="colemak-swappable"></a>
### Colemak-DH / QWERTY Swappable
I code primarily using Colemak-DH on ZSA's Moonlander keyboard (check out my [keyboard config](https://github.com/mrdandelion6/ViMak-Moonlander)) , and when I have to use a regular staggered keyboard I use QWERTY. For this reason , I made a user command: *ToggleColemak* , which lets you swap between different key layouts instantly. You can find it in `lua/core/keymaps.lua`. You can also press `<leader>tc` to trigger it.

Going into Colemak-DH layout swaps your movement keys from **hjkl to knei**. This include buffer jumping , telescope , and everything else I could remember where movement is involved. Here is a list of keys swapped:
```bash
# pressing the left key (in []) triggers the action for key on the right
['k'] = 'h',
['n'] = 'j',
['e'] = 'k',
['i'] = 'l',

['K'] = 'H',
['N'] = 'J',
['E'] = 'K',
['I'] = 'L',

# notice, these are not symmetrical to above
['h'] = 'n',
['j'] = 'e',
['l'] = 'i',

['H'] = 'N',
['J'] = 'E',
['L'] = 'I',
```
These remaps affect key sequences as well. See [keymaps.lua](lua/core/keymaps.lua) for more detail.

### Local Settings & Learn-to-Code Notes
You will find a file `.localsettings_template.json` in the root of this repo. Upon running `nvim` for the first time with this configuration , a file `.localsettings.json` will be generated. This file allows for persistent local settings that won't push to the repo. For example , when you toggle to Colemak-DH from QWERTY , your next `nvim` session will remember that you are currently on Colemak.

You can also edit the **"notes_path"** JSON key to point to the path of any text notes you want to frequently look at. For instance , I have a big repo of all my various coding notes: [Learn-to-Code](https://github.com/mrdandelion6/Learn-to-Code). Pressing `<leader>fn` opens a telescope that will search through my notes repo. I find myself using this very often , if I ever forget anything and want a quick `man` like seach , or if I want to jot something new down. Feel free to clone my Learn-to-Code repo and use it.

If you want to exclude particular file name patterns from being autoformated by `nvim` when saving buffers , then you can also add patterns in the **"exclude_autoformat"** JSON key.

### Cursor Always Centered
The cursor is always kept centered , even at the end of a file. Normally , even with `scrolloff = 999` , Neovim uncenters the cursor at the end of the file. This is very annoying if your coding at the end of a file and have to constantly look down at the bottom edge of your screen. To get around this I made an autocommand that keeps the cursor fixed at the center , even at EOF. Will make this into a standalone plugin soon.

<a id="terminal-title"></a>
### Terminal Buffers Keep Title as PWD
There is only one global status line instead of one per buffer. This is to keep things compact. The global status line displays the git root directory name of file in the current buffer (blank if not a repository). In return, each buffer gets its own small title at the top to indicate file name. For terminal buffers , this header corresponds to the PWD of the terminal.

This is done through modifying `.bashrc` to send a signal to Neovim whenever you change directory or start a shell. You must copy some of the contents of `shell/bashrc.sh` into your own `~/.bashrc` script for this to work. I have not yet implemented a Windows equivalent feature :(

### Runnable Jupyter Notebooks
Execute code cells in `.ipynb` , `.md` , and `.qmd` files directly in Neovim using Jupyter kernels. Navigate between cells with `]]`/`[[` , initialize kernels with `<leader>ri` , and run cells with `<leader>rc`.

**Note:** This feature is currently only enabled on Linux. Windows support is not yet implemented. If you want to experiment with it on Windows, you'll need to modify the platform check in `init.lua`.

See the full guide: [doc/linux/notebooks.md](doc/linux/notebooks.md).

### LaTeX Compilation
You can type and compile LaTeX locally through Neovim instead of using Overleaf. This is mostly handled my the `lervag/vimtex` plugin. You will need to install the following dependencies:
- pdflatex
- Zathura for linux
- SumatraPDF for Windows

If you want to use other compilers such as `xelatex` , create a `.latexmkrc` file in the same directory as the `.tex` file and specify the following:
```bash
$pdf_mode = 5; # uses xelatex
$postscript_mode = 0;
$dvi_mode = 0;
```
Here are what the different values for `pdf_mode` change for the compilation process:
- 1: uses `pdflatex` engine
- 2: uses `latex` + `dvips` + `ps2pdf` (requires `$postscript_mode = 1`)
- 3: uses `latex` + `dvipdf` (or `dvipdfm`/`dvipdfmx`, requires `$dvi_mode = 1`)
- 4: uses `lualatex` engine
- 5: uses `xelatex` engine

If no `.latexmkrc` file is found , falls back to `pdflatex`. Note that `pdflatex` , `xelatex` , and `lualatex` require `postscript_mode` and `dvi_mode` to be set to zero.

Hot reloading should be enabled by default for either Zathura or SumatraPDF (this config decides which to use depending on whether you're using Linux or Windows). Every time you write the file `:w` , Neovim will automatically invoke the compilation for whatever `pdf_mode` you have set and update the PDF.

## Files
You can find a breakdown of my files and what they are used for in [doc/files.md](doc/files.md).

## Terminal & Background
I use Wezterm for my terminal since it works well for both Linux and Windows. You can find my configuration for Wezterm on Arch in my [.dotfiles repo](https://github.com/mrdandelion6/.dotfiles) , and for Windows in [.winfiles repo](https://github.com/mrdandelion6/.winfiles).

You can also find the background image I use for my terminal and my fastfetch configuration in my `.dotfiles` repo.

Reach out to me with any questions. Happy coding.
