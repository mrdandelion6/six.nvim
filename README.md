# six.nvim ![Version](https://img.shields.io/badge/version-2.0-blue)

welcome to my custom configuration for neovim. this configuration was originally forked from **kickstart.nvim** but has been greatly changed.

![Screenshot](samples/nvim.png)

## latest changes

### v2.0

- **jupyter notebooks & code execution**: major feature addition - execute code cells in `.ipynb` , `.md` , and `.qmd` files using jupyter kernels via `molten.nvim` and `quarto.nvim`. navigate cells with `]]`/`[[` , run with `<leader>rc`. currently linux-only.
- **treesitter text objects**: added custom text objects for markdown code cells - select with `ac`/`ic` , jump between cells , and navigate functions
- **formatting system overhaul**: unified formatting with lsp and conform integration. toggle per-buffer formatting with `<leader>tf`
- **improved performance**: replaced `vim.fn.system()` with `vim.system()` for git operations , eliminating shell profile invocations and significantly reducing lag
- **CSV rendering**: added `csvview.nvim` for readable csv display with automatic view toggling
- **documentation refactor**: reorganized setup guides and added comprehensive notebooks documentation
- **plugin cleanup**: removed `mini.nvim` , fixed various keybinding conflicts , improved oil.nvim integration
- **latex snippets**: expanded snippet collection with proof environments , math commands , and custom macros
- **bug fixes**: fixed autoformatting on new buffers , clangd arguments , csv navigation conflicts , and stylua lsp false positives

see more in [CHANGELOG.md](CHANGELOG.md)

## setup

you will generally need the following dependencies installed and on PATH:

- curl
- unzip
- python
- python-pip
- nodejs
- npm
- ripgrep
- zoxide

for more **specific set up instructions** depending on your OS and distribution , see the guides inside `doc/`:

- [Ubuntu/Debian](doc/linux/ubuntu/setup.md)
- [Windows](doc/windows/setup.md)
- [Arch](doc/linux/arch/setup.md)

## key features

this is an all purpose configuration with a focus on coding in many different programming languages. below is an overview of some key features of my config. i plan on making separate plugins for all of these eventually.

<a id="colemak-swappable"></a>

### colemak-dh / qwerty swappable

i code primarily using colemak-dh on ZSA's Moonlander keyboard (check out my [keyboard config](https://github.com/mrdandelion6/ViMak-Moonlander)) , and when i have to use a regular staggered keyboard i use qwerty. for this reason , i made a user command: _ToggleColemak_ , which lets you swap between different key layouts instantly. you can find it in `lua/core/keymaps.lua`. you can also press `<leader>tc` to trigger it.

going into colemak-dh layout swaps your movement keys from **hjkl to knei**. this include buffer jumping , telescope , and everything else i could remember where movement is involved. here is a list of keys swapped:

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

these remaps affect key sequences as well. see [keymaps.lua](lua/core/keymaps.lua) for more detail.

### local settings & learn-to-code notes

you will find a file `.localsettings_template.json` in the root of this repo. upon running `nvim` for the first time with this configuration , a file `.localsettings.json` will be generated. this file allows for persistent local settings that won't push to the repo. for example , when you toggle to colemak-dh from qwerty , your next `nvim` session will remember that you are currently on colemak.

you can also edit the **"notes_path"** json key to point to the path of any text notes you want to frequently look at. for instance , i have a big repo of all my various coding notes: [learn-to-code](https://github.com/mrdandelion6/learn-to-code). pressing `<leader>fn` opens a telescope that will search through my notes repo. i find myself using this very often , if i ever forget anything and want a quick `man` like seach , or if i want to jot something new down. feel free to clone my learn-to-code repo and use it.

if you want to exclude particular file name patterns from being autoformated by `nvim` when saving buffers , then you can also add patterns in the **"exclude_autoformat"** json key.

### cursor always centered

the cursor is always kept centered , even at the end of a file. normally , even with `scrolloff = 999` , neovim uncenters the cursor at the end of the file. this is very annoying if your coding at the end of a file and have to constantly look down at the bottom edge of your screen. to get around this i made an autocommand that keeps the cursor fixed at the center , even at eof. will make this into a standalone plugin soon.

<a id="terminal-title"></a>

### terminal buffers keep title as pwd

there is only one global status line instead of one per buffer. this is to keep things compact. the global status line displays the git root directory name of file in the current buffer (blank if not a repository). in return, each buffer gets its own small title at the top to indicate file name. for terminal buffers , this header corresponds to the pwd of the terminal.

this is done through modifying `.bashrc` to send a signal to neovim whenever you change directory or start a shell. you must copy some of the contents of `shell/bashrc.sh` into your own `~/.bashrc` script for this to work. i have not yet implemented a windows equivalent feature :(

### runnable jupyter notebooks

execute code cells in `.ipynb` , `.md` , and `.qmd` files directly in neovim using jupyter kernels. navigate between cells with `]]`/`[[` , initialize kernels with `<leader>ri` , and run cells with `<leader>rc`.

**note:** this feature is currently only enabled on linux. windows support is not yet implemented. if you want to experiment with it on windows, you'll need to modify the platform check in `init.lua`.

see the full guide: [doc/linux/notebooks.md](doc/linux/notebooks.md).

### latex compilation

you can type and compile latex locally through neovim instead of using overleaf. this is mostly handled my the `lervag/vimtex` plugin. you will need to install the following dependencies:

- pdflatex
- Zathura for linux
- SumatraPDF for windows

see [doc/latex.md](doc/latex.md) for more details.

## files

you can find a breakdown of my files and what they are used for in [doc/files.md](doc/files.md).

## terminal & background

i use wezterm for my terminal since it works well for both linux and windows. you can find my configuration for wezterm on arch in my [.dotfiles repo](https://github.com/mrdandelion6/.dotfiles) , and for windows in [.winfiles repo](https://github.com/mrdandelion6/.winfiles).

you can also find the background image i use for my terminal and my fastfetch configuration in my `.dotfiles` repo.

reach out to me with any questions.
