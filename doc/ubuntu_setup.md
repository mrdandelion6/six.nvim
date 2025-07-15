# Ubuntu Setup
Install the following plugin dependencies:

## Base
The following dependencies are needed for multliple plugins:
```bash
sudo apt install curl
sudo apt install unzip

# python
sudo apt install python3 python3-pip

# node and npm, many LSP need this
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt install nodejs
```

### telescope.nvim
```bash
sudo apt install ripgrep
```

## For LaTeX
```bash
# good pdf viewer with hot reloading
sudo apt install zathura zathura-pdf-mupdf

# if issuse with mupdf backend , install poppler
sudo apt install zathura-pdf-poppler

# full tex live , includes all major latex packages. ~4-5GB
sudo apt install texlive-full
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
# for magick_cli
sudo apt install luarocks imagemagick libmagick++-dev
# for magick_rock
sudo apt install libmagickwand-dev
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
