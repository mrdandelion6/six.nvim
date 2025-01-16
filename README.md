# faisal.nvim

forked from kickstart.nvim.

## files
### non-config
- bashrc.sh
- ascii_art/
- background_images/

### config
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

## setup

### ubuntu/debian

install the following plugin dependencies

#### image.nvim
```bash
# for magick_cli
sudo apt install luarocks imagemagick libmagick++-dev
# for magick_rock
sudo apt install libmagickwand-dev
```

#### molten.nvim
```bash
# create a virtual environment
cd ~/.envs # path matters
python -m venv neovim
source ~/.envs/neovim/bin/activate

# install the following deps
pip install pynvim jupyter_client cairosvg plotly kaleido pnglatex pyperclip nbformat jupytext
```
if you want to use a different path than `~/.envs/neovim/`, then you must edit `lua/core/options.lua` and change this line:
```lua
vim.g.python3_host_prog = vim.fn.expand '~/.envs/neovim/bin/python3'
```

reach out to me with any questions. happy coding
