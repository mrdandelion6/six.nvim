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
```

### telescope.nvim
```bash
scoop install ripgrep
```

## For Jupyter Notebooks
Have not attempted any Windows support for this. You can try to mimic the dependencies in [ubuntu_setup.md](ubuntu_setup.md).
