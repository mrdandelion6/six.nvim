# windows setup

i am using `scoop`. you can use whatever package manager that works for you.

## installing scoop

```bash
# in powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
irm get.scoop.sh | iex

# verify
scoop help
```

install the following plugin dependencies:

## base

the following dependencies are needed for multliple plugins:

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

it is recommended to download miktex from: https://miktex.org/ rather than `scoop` for better windows integration, and it also comes with texworks, which is the pdf viewer we use.

**installation:**

1. go to https://miktex.org/download
2. download the **net installer** (not basic installer)
3. run as administrator and choose **"install miktex for all users"**
4. when prompted for installation scope, select **"complete miktex"** to install all packages at once (~4gb)
    - alternative: choose "basic miktex" if you prefer to install packages as needed

**after installation:**

1. open **miktex console** and go to **updates** tab
2. click **"check for updates"** and install all available updates
3. verify installation by running in command prompt:
    ```cmd
    latex --version
    pdflatex --version
    latexmk --version
    texworks --version
    ```

if you want svg rendering support , you must install inkscape. you can do this with scoop or anything else ,

```sh
scoop install inkscape
```

## for jupyter notebooks

have not attempted any windows support for this. you can try to mimic the dependencies in [ubuntu_setup.md](ubuntu_setup.md).
