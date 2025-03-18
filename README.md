# faisal.nvim

Welcome to my custom configuration for neovim. this configuration was originally forked from kickstart.nvim but has been greatly changed.

This is an all purpose configuration with a focus on coding in many different programming languages. Below is an overview of some key features:

## Key features

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

note that `kickstart/` contains configuration from the kickstart.nvim that i am not using.

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
pip install pynvim jupyter_client cairosvg plotly kaleido pnglatex pyperclip nbformat jupytext jupyter jupyterlab
```
if you want to use a different path than `~/.envs/neovim/`, then you must edit `lua/core/options.lua` and change this line:
```lua
vim.g.python3_host_prog = vim.fn.expand '~/.envs/neovim/bin/python3'
```

you will also need quarto cli:
```bash
# get latest release
wget https://github.com/quarto-dev/quarto-cli/releases/download/v1.6.40/quarto-1.6.40-linux-amd64.deb

# install
sudo dpkg -i quarto-1.6.40-linux-amd64.deb
```

reach out to me with any questions. happy coding
