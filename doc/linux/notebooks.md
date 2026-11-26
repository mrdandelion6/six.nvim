# notebooks

once you have followed the guide for setting up the plugins for running code in jupyter notebook , markdown , and quarto files in [arch/setup.md](doc/linux/arch/setup.md) , then you can proceed with reading this guide.

## quarto & markdown files

with this setup , you can run code inside any file type on kernels. i have only really experimented with this for python jupyter kernels , but you can definitely make it work for others. most commonly , you will want to be working inside `.md` (markdown) or `.qmd` (quarto) files. for our purposes , there is pretty much no difference between markdown and quarto files--we can run both.

quarto files are used by other tools like **quarto cli** and can be executed. you can just rename any markdown file to have a `.qmd` extension--they're both plaintext files with the same syntax. for this reason , you may prefer to write your notebooks with a `.qmd` extension instead.

## jupyter notebook files

for `ipynb` files , `quarto.nvim` should render them as markdown files in your buffer. it is recommended that you just use `.qmd` files as an alternative to `.ipynb` files entirely when coding. quarto files are better to track in version control. since `quarto.nvim` converts the `.ipynb` files to markdown anyway , why not just work directly in quardo markdown ? moreover , you can use tools like `jupytext` to convert back to `.ipynb` files if you need to share or render those.

if you want to stick with the `.ipynb` files for some reason , that is fine--`quarto` will handle rendering them as markdown files. when viewing a `.ipynb` file , a markdown file is rendered and you will see this in your version control. when you leave neovim , this markdown file will be deleted , and any changes you saved will then be intelligently applied to the original `.ipynb` file.

## usage

### navigating cells

you can use `]]` to go to the next code cell and `[[` to go to the previous one. this is configured in [treesitter.lua](lua/plugins/language_support/treesitter.lua).

### initializing molten

before being able to do things like run code cells , you must initialize `molten` with the proper kernel. press `<leader>ri` to initialize a kernel or use the `:MoltenInit` command.

### registering a jupyter kernel

to register a kernel so that you can select it for `:MoltenInit` , you must first create the `venv` , activate it , and then do the following:

```bash
# install ipykernel so the venv interpreter can serve as jupyter kernel
pip install ipykernel

# register kernel
python -m ipykernel install --user --name=myproject --display-name="bababooey"
```

then you will see an kernel with the name `bababooey` when doing `:MoltenInit`.

### running code cells

once you have initialized `molten` with a kernel , you can run code cells by entering `<leader>rc` while inside a code cell. you can see more keymaps in [molten.lua](lua/plugins/notebooks/molten.lua).

### keeping the kernel attached

`molten` drops a buffer's kernel whenever that buffer is unloaded , so you lose all your variables and have to `:MoltenInit` again. so in a notebook with a running kernel , avoid anything that unloads the buffer:

- `:e` / `:e!` (reloading the file this way unloads it first)
- `:bd` / `:bw` (deleting the notebook buffer)

closing a window showing the notebook is fine , since the buffer stays loaded (`hidden` is on). you don't need `:e` to see changes made to the file outside nvim (ex. by claude code in a `:terminal`) either. [cmds.lua](lua/core/cmds.lua) runs `:checktime` on `WinEnter` , `BufEnter` , `FocusGained` and `CursorHold` , which reloads the file without unloading the buffer. if you do unload it by accident , [molten.lua](lua/plugins/notebooks/molten.lua) clears the old outputs it leaves behind , so just `:MoltenInit` and rerun your cells.
