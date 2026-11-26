# arch setup

read this to learn manual set up for neovim on arch linux. if you are looking for a quick install , just use [bootstrap.sh](install/boostrap.sh). read more [here](install/README.md).

install the following plugin dependencies:

## base

the following dependencies are needed for multliple plugins:

```bash
sudo pacman -S curl unzip yarn

# python
sudo pacman -S python python-pip

# node and npm, many LSP need this
sudo pacman -S nodejs npm

# tree-sitter-cli (nvim-treesitter) and stylua (lua formatting) are not installed here.
# install/bootstrap.sh puts pinned versions in ~/.local/share/nvim/bootstrap/bin , which
# only nvim has on its PATH
./install/bootstrap.sh
```

usually , we install formatters / LSP tools through mason , which is automatically handled by the plugins. but installing `stylua` through mason leads `nvim-lspconfig` to launch it as an LSP server , even though we only want to use it as a formatter. this causes errors , hence bootstrap installs it instead (see `install/README.md`).

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

the venv is created with [uv](https://github.com/astral-sh/uv) at `<venv_path>/neovim`, where `venv_path` comes from `.localsettings.json`:

```json
"venv_path": "~/.envs"
```

```bash
# create a virtual environment (uv downloads python 3.14 if it isn't installed)
uv venv --python 3.14 ~/.envs/neovim # path matters , must match venv_path

# install the following deps (uv venvs have no pip inside , use uv pip)
uv pip install --python ~/.envs/neovim/bin/python pynvim jupyter_client cairosvg plotly kaleido pnglatex pyperclip nbformat jupytext jupyter jupyterlab
```

`install/molten.sh` does both steps for you.

you will also need quarto cli:

```bash
# get latest release
yay -S quarto-cli
```

molten is a remote plugin so now you must run `:UpdateRemotePlugins` command in `nvim` , which should output:

```bash
remote/host: python3 host registered plugins ['molten']
remote/host: generated rplugin manifest: $HOME/.local/share/nvim/rplugin.vim
```

if you have python3 issues , make sure your `venv_path` points to an existing virtual environment with the required deps listed above.
