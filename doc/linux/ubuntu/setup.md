# ubuntu setup

read this to get started with setting up neovim on ubuntu. install the following plugin dependencies:

## base

the following dependencies are needed for multliple plugins:

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

usually , we install formatters / LSP tools through mason , which is automatically handled by the plugins. but installing `stylua` through mason leads `nvim-lspconfig` to launch it as an LSP server , even though we only want to use it as a formatter. this causes errors , hence we install it manually.

### telescope.nvim

```bash
sudo apt install ripgrep
```

## for LaTeX

```bash
# good pdf viewer with hot reloading
sudo apt install zathura zathura-pdf-mupdf

# if issues with mupdf backend , install poppler
sudo apt install zathura-pdf-poppler

# full tex live , includes all major latex packages. ~4-5GB
sudo apt install texlive-full

# for SVG support
sudo apt install inkscape
```

## for jupyter notebooks

the plugins inside `lua/notebooks/` are only needed if you want to render and execute code inside jupyter notebooks or quarto/markdown files. note that i haven't tested this out for ubuntu yet , only arch.. so it may not work but i believe in your ability to fix it :)

install the following dependendies:

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

if you want to use a different path than `~/.envs/neovim/`, then you must edit `.localsettings.json` and change this key:

```json
"venv_path": "~/.envs"
```

you will also need quarto cli:

```bash
# get latest release
wget https://github.com/quarto-dev/quarto-cli/releases/download/v1.6.40/quarto-1.6.40-linux-amd64.deb

# install
sudo dpkg -i quarto-1.6.40-linux-amd64.deb
```

molten is a remote plugin so now you must run `:UpdateRemotePlugins` command in `nvim` , which should output:

```bash
remote/host: python3 host registered plugins ['molten']
remote/host: generated rplugin manifest: $HOME/.local/share/nvim/rplugin.vim
```

if you have python3 issues , make sure your `venv_path` points to an existing virtual environment with the required deps listed above.
