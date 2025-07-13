# Arch Setup
Install the following plugin dependencies:

## Base
The following dependencies are needed for multliple plugins:
```bash
sudo pacman -S curl
sudo pacman -S unzip

# python
sudo pacman -S python python-pip

# node and npm, many LSP need this
sudo pacman -S nodejs npm
```

### telescope.nvim
```bash
sudo pacman -S ripgrep
```

## For LaTeX
```bash
# good pdf viewer with hot reloading
sudo pacman -S zathura zathura-pdf-mupdf

# full tex live , includes all major latex packages
sudo pacman -S texlive-most textlive-lang
# includes pdflatex , xelatex , lualatex , latexmk , and common latex packages
```

## For Jupyter Notebooks
The following plugins are only needed if you want to render and execute code inside Jupyter notebooks. Note that you may run into several problems in making this work properly. If I'm being honest , I've been lazy to figure out how to make this work exactly. I recommend not trying this unless you absolutely want to use Neovim on notebooks.

To begin with, rename the following files:
```
mv quarto.lua.unstable quarto.lua
mv images.lua.unstable images.lua
mv render.lua.unstable render.lua
mv repl.lua.unstable repl.lua
```

Now install the following dependendies:
### image.nvim
```bash
# for magick_cli and magick_rock
sudo pacman -S luarocks imagemagick
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

