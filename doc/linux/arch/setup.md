# arch setup

read this to get started with setting up neovim on arch linux. install the following plugin dependencies:

## base

the following dependencies are needed for multliple plugins:

```bash
sudo pacman -S curl unzip yarn

# python
sudo pacman -S python python-pip

# node and npm, many LSP need this
sudo pacman -S nodejs npm

# tree-sitter-cli used by certain LSP like for latex
sudo npm install -g tree-sitter-cli

# lua formatting
sudo pacman -S stylua
```

usually , we install formatters / LSP tools through mason , which is automatically handled by the plugins. but installing `stylua` through mason leads `nvim-lspconfig` to launch it as an LSP server , even though we only want to use it as a formatter. this causes errors , hence we install it manually.

### telescope.nvim

```bash
sudo pacman -S ripgrep zoxide
```

## for LaTeX

```bash
# good pdf viewer with hot reloading
sudo pacman -S zathura zathura-pdf-mupdf

# if issues with mupdf backend , install poppler
sudo pacman -S zathura-pdf-poppler

# full tex live , includes all major latex packages. ~2-3GB
sudo pacman -S texlive
# includes pdflatex , xelatex , lualatex , latexmk , and common latex packages

# for SVG support
sudo pacman -S inkscape
```

## for jupyter notebooks

the plugins inside `lua/notebooks/` are only needed if you want to render and execute code inside jupyter notebooks or quarto/markdown files.

install the following dependendies:

### image.nvim

```bash
# for magick_cli and magick_rock
sudo pacman -S luarocks imagemagick lua51
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
yay -S quarto-cli

# install
sudo dpkg -i quarto-1.6.40-linux-amd64.deb
```

molten is a remote plugin so now you must run `:UpdateRemotePlugins` command in `nvim` , which should output:

```bash
remote/host: python3 host registered plugins ['molten']
remote/host: generated rplugin manifest: $HOME/.local/share/nvim/rplugin.vim
```

if you have python3 issues , make sure your `venv_path` points to an existing virtual environment with the required deps listed above.
