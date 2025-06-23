# faisal.nvim

Welcome to my custom configuration for Neovim. This configuration was originally forked from **kickstart.nvim** but has been greatly changed.

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
- [Ubuntu/Debian](doc/ubuntu_setup.md)
- [Windows](doc/windows_setup.md)
- [Arch](doc/arch_setup.md)

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
These remaps affect key sequences as well. See [keymaps.lua](lua/core/keymaps.lua) to see in more detail.

### Local Settings & Learn-to-Code Notes
You will find a file `.localsettings_template.json` in the root of this repo. Upon running `nvim` for the first time wit this configuration , a file `.localsettings.json` will be generated. This file allows for persistent local settings that won't push to the repo. For example , when you toggle to Colemak-DH from QWERTY , your next `nvim` session will remember that you are currently on Colemak.

You can also edit the **"notes_path"** JSON key to point to the path of any text notes you want to frequently look at. For instance , I have a big repo of all my various coding notes: [Learn-to-Code](https://github.com/mrdandelion6/Learn-to-Code). Pressing `<leader>fn` opens a telescope that will search through my notes repo. I find myself using this very often , if I ever forget anything and want a quick `man` like seach , or if I want to jot something new down. Feel free to clone my Learn-to-Code repo and use it.

If you want to exclude particular file name patterns from being autoformated by `nvim` when saving buffers , then you can also add patterns in the **"exclude_autoformat"** JSON key.

### Cursor Always Centered
The cursor is always kept centered , even at the end of a file. Normally , even with `scrolloff = 999` , Neovim uncenters the cursor at the end of the file. This is very annoying if your coding at the end of a file and have to constantly look down at the bottom edge of your screen. To get around this I made an autocommand that keeps the cursor fixed at the center , even at EOF. Will make this into a standalone plugin soon.

<a id="terminal-title"></a>
### Terminal Buffers Keep Title as PWD
There is only one global status line at a time to keep things compact. The global status line displays the git root directory name of file in the current buffer (blank if not a repository). Each buffer also gets its own header at the top to indicate file name. For terminal buffers , this header corresponds to the PWD of the terminal.

This is done through modifying `.bashrc` to send a signal to Neovim whenever you change directory. You must copy the contents of `bashrc.sh` into your own `~/.bashrc` script for this to work. This is still very buggy and I am working on a more reliable method. I have not yet implemented a Windows equivalent feature :(

### Runnable Jupyter Notebooks
An unstable feature I am working on. Currently the plugin files for this end in the suffix `.unstable`. I didn't make a separate branch for this because I follow bad practices sometimes , cry about it.

When complete , should be able to view Jupyter notebooks like they are markdown files with runnable segments of code.

## Files
You can find a breakdown of my files and what they are used for in [doc/files.md](doc/files.md).

## Terminal & Background
I use Wezterm for my terminal in which I run Neovim as I develop on both Linux and Windows. You can find my configuration for Wezterm on Arch in my [.dotfiles repo](https://github.com/mrdandelion6/.dotfiles) , and for Windows in [.winfiles repo](https://github.com/mrdandelion6/.winfiles).

The background image I use for my terminal can be found [here](). And the different ASCII art I use can be found [here]().

## TODO
Here is a list of featues I plan on implementing.

### Visual
- On the right side of buffers , add symbol to indicate errors in file (relative to size).
- Fix bug with cursor not centering based on height. Right now , cursor centers based on lines above which is skewed for lines that bleed over to next row. Make this into its own plugin.
- Make bottom right status box transparent and chang the color of text inside it to pink.
- Add terminal top bar updates for PowerShell users

### Color Scheme
- Make class definitions light orange.
- Make constructor/destructor definition and calls same color as functions (light pink).
- Make class type light orange or keep it as light red depending on definition and constructor/destructor colors.
- Make (*) same color as string when it's for pointer.
- Make (&) same color as string when it's for address.
- Make header name color different than regular string color if possible. Make it grey or light red.

### Plugins
- Fix Telescope bug with `ripgrep` not finding empty textfiles.

### Add LSP
- CUDA
- x86
- LaTeX
- PowerShell
- Java
- Rust
- Verilog
- Swift : Mason currently throwing an error when using `bash/swift_sourcekit_lsp.sh` in `lua/plugins/lsp.lua`.

### Long Term
Not going to do these anytime soon.
- Make Jupyter notebooks work using the plugins currently suffixed with `.unstable` in lua/plugins.

### Other Bugs/Featues
- Get_git_root() causes lag on Windows whenever it runs so set up a cache table for filepaths so it is only called once on files. Also set it to only be called when we are viewing a text file in the buffer (no terminal).

Reach out to me with any questions. Happy coding.
