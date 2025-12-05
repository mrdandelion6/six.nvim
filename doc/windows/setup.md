# Windows Setup

I am using `scoop`. You can use whatever package manager that works for you.

## Installing Scoop

```bash
# in powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
irm get.scoop.sh | iex

# verify
scoop help
```

Install the following plugin dependencies:

## Base

The following dependencies are needed for multliple plugins:

```bash
scoop install curl unzip

# python
scoop install python

# node and npm, many LSP need this
scoop install nodejs

# used by certain LSP like latex
npm install -g tree-sitter-cli
```

### telescope.nvim

```bash
scoop install ripgrep zoxide
```

## LaTeX

It is recommended to download MiKTeX from: https://miktex.org/ rather than `scoop` for better Windows integration, and it also comes with TeXworks, which is the PDF viewer we use.

**Installation:**

1. Go to https://miktex.org/download
2. Download the **Net Installer** (not Basic Installer)
3. Run as Administrator and choose **"Install MiKTeX for all users"**
4. When prompted for installation scope, select **"Complete MiKTeX"** to install all packages at once (~4GB)
    - Alternative: Choose "Basic MiKTeX" if you prefer to install packages as needed

**After installation:**

1. Open **MiKTeX Console** and go to **Updates** tab
2. Click **"Check for updates"** and install all available updates
3. Verify installation by running in Command Prompt:
    ```cmd
    latex --version
    pdflatex --version
    latexmk --version
    texworks --version
    ```

If you want SVG rendering support , you must install Inkscape. You can do this with Scoop or anything else ,

```sh
scoop install inkscape
```

## For Jupyter Notebooks

Have not attempted any Windows support for this. You can try to mimic the dependencies in [ubuntu_setup.md](ubuntu_setup.md).
