# Notebooks

Once you have followed the guide for setting up the plugins for running code in jupyter notebook , markdown , and quarto files in [arch/setup.md](doc/linux/arch/setup.md) , then you can proceed with reading this guide.

## Quarto & Markdown Files

With this setup , you can run code inside any file type on kernels. I have only really experimented with this for Python jupyter kernels , but you can definitely make it work for others. Most commonly , you will want to be working inside `.md` (markdown) or `.qmd` (quarto) files. For our purposes , there is pretty much no difference between markdown and quarto files--we can run both.

Quarto files are used by other tools like **Quarto CLI** and can be executed. You can just rename any markdown file to have a `.qmd` extension--they're both plaintext files with the same syntax. For this reason , you may prefer to write your notebooks with a `.qmd` extension instead.

## Jupyter Notebook Files

For `ipynb` files , `quarto.nvim` should render them as markdown files in your buffer. It is recommended that you just use `.qmd` files as an alternative to `.ipynb` files entirely when coding. Quarto files are better to track in version control. Since `quarto.nvim` converts the `.ipynb` files to markdown anyway , why not just work directly in quardo markdown ? Moreover , you can use tools like `jupytext` to convert back to `.ipynb` files if you need to share or render those.

If you want to stick with the `.ipynb` files for some reason , that is fine--`quarto` will handle rendering them as markdown files. When viewing a `.ipynb` file , a markdown file is rendered and you will see this in your version control. When you leave Neovim , this markdown file will be deleted , and any changes you saved will then be intelligently applied to the original `.ipynb` file.

## Usage

### Navigating Cells

You can use `]]` to go to the next code cell and `[[` to go to the previous one. This is configured in [treesitter.lua](lua/plugins/language_support/treesitter.lua).

### Initializing Molten

Before being able to do things like run code cells , you must initialize `molten` with the proper kernel. Press `<leader>ri` to initialize a kernel or use the `:MoltenInit` command.

### Registering a Jupyter Kernel

To register a kernel so that you can select it for `:MoltenInit` , you must first create the `venv` , activate it , and then do the following:

```bash
# install ipykernel so the venv interpreter can serve as jupyter kernel
pip install ipykernel

# register kernel
python -m ipykernel install --user --name=myproject --display-name="bababooey"
```

Then you will see an kernel with the name `bababooey` when doing `:MoltenInit`.

### Running Code Cells

Once you have initialized `molten` with a kernel , you can run code cells by entering `<leader>rc` while inside a code cell. You can see more keymaps in [molten.lua](lua/plugins/notebooks/molten.lua).
