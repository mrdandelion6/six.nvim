# Ubuntu Setup
Read this to get started with setting up Neovim on Ubuntu. Install the following plugin dependencies:

## Base
The following dependencies are needed for multliple plugins:
```bash
sudo apt install curl unzip yarn

# python
sudo apt install python3 python3-pip

# node and npm, many LSP need this
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt install nodejs

# tree-sitter-cli used by certain LSP like for latex
sudo npm install -g tree-sitter-cli

# lua formatting
sudo apt install stylua
```
Usually , we install formatters / LSP tools through Mason , which is automatically handled by the plugins. But installing `stylua` through Mason leads `nvim-lspconfig` to launch it as an LSP server , even though we only want to use it as a formatter. This causes errors , hence we install it manually.

### telescope.nvim
```bash
sudo apt install ripgrep
```

## For LaTeX
```bash
# good pdf viewer with hot reloading
sudo apt install zathura zathura-pdf-mupdf

# if issues with mupdf backend , install poppler
sudo apt install zathura-pdf-poppler

# full tex live , includes all major latex packages. ~4-5GB
sudo apt install texlive-full
```

## For Jupyter Notebooks
The plugins inside `lua/notebooks/` are only needed if you want to render and execute code inside Jupyter notebooks or quarto/markdown files. Note that I haven't tested this out for Ubuntu yet , only Arch.. so it may not work but I believe in your ability to fix it :)

Install the following dependendies:
### image.nvim
```bash
# for magick_cli
sudo apt install luarocks imagemagick libmagick++-dev
# for magick_rock
sudo apt install libmagickwand-dev lua5.1 liblua5.1-0-dev
```

### molten.nvim
```bash
# create a virtual environment
cd ~/.envs # path matters
python -m venv neovim
source ~/.envs/neovim/bin/activate

# install the following deps
pip install pynvim jupyter_client cairosvg plotly kaleido pnglatex pyperclip nbformat jupytext jupyter jupyterlab
```

If you want to use a different path than `~/.envs/neovim/`, then you must edit `.localsettings.json` and change this key:
```json
"venv_path": "~/.envs"
```

You will also need quarto cli:
```bash
# get latest release
wget https://github.com/quarto-dev/quarto-cli/releases/download/v1.6.40/quarto-1.6.40-linux-amd64.deb

# install
sudo dpkg -i quarto-1.6.40-linux-amd64.deb
```

Molten is a remote plugin so now you must run `:UpdateRemotePlugins` command in `nvim` , which should output:
```bash
remote/host: python3 host registered plugins ['molten']
remote/host: generated rplugin manifest: $HOME/.local/share/nvim/rplugin.vim
```
If you have python3 issues , make sure your `venv_path` points to an existing virtual environment with the required deps listed above.
