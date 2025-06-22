# faisal.nvim

welcome to my custom configuration for neovim. this configuration was originally forked from kickstart.nvim but has been greatly changed.

this is an all purpose configuration with a focus on coding in many different programming languages. below is an overview of some key features:

## Key features

## Files
### Non-config
- bashrc.sh
- ascii_art/
- background_images/

### Config
- init.lua
- lua/
  - user/
    - init.lua
    - plugins.lua
    - keymaps.lua
    - plugins.lua
    - autocmds.lua
- after/
- plugin/
- ftplugin/
- snippets/

note that `kickstart/` contains configuration from the kickstart.nvim that i am not using.

## Setup

# TODO
## Visual
- On the right side of buffers , add symbol to indicate errors in file (relative to size).
- Fix bug with cursor not centering based on height. Right now , cursor centers based on lines above which is skewed for lines that bleed over to next row.
- Fix top bar not updating with terminal's PWD sometimes.
- Make bottom right status box transparent and chang the color of text inside it to pink.

## Color Scheme
- Make class definitions light orange.
- Make constructor/destructor definition and calls same color as functions (light pink).
- Make class type light orange or keep it as light red depending on definition and constructor/destructor colors.
- Make (*) same color as string when it's for pointer.
- Make (&) same color as string when it's for address.
- Make header name color different than regular string color if possible. Make it grey or light red.

## Plugins
- Fix Telescope bug with `ripgrep` not finding empty textfiles.

## Add LSP
- CUDA
- x86
- LaTeX
- PowerShell
- Java
- Rust
- Verilog

## Long Term
- Make Jupyter notebooks work using the plugins currently suffixed with `.unstable` in lua/plugins.

Reach out to me with any questions. Happy coding.
