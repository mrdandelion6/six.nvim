# LaTeX

## Deps

You will need:

- pdflatex
- Zathura for linux
- SumatraPDF for Windows

## Snippets

To make snippets for a filetype `ft` , edit `snippets/ft.lua`. For example , for c++ snippets , you can edit `snippets/cpp.lua`.

## Custom Compilation

For custom compilation commands , create a `.latexmkrc` file in the same directory as the `.tex` file. You can configure this file to achieve things like using other LaTeX compilers and passing arguments to said compilers.

### XeLaTeX

Since you will usually use `pdflatex` , that is the default compiler without any `.latexmkrc` file configured. If you want to use other compilers such as `xelatex` , edit `.latexmkrc` as follows ,

```bash
$pdf_mode = 5; # uses xelatex
$postscript_mode = 0;
$dvi_mode = 0;
```

### Other Compilers

Here are what the different values for `pdf_mode` change for the compilation process:

- 1: uses `pdflatex` engine
- 2: uses `latex` + `dvips` + `ps2pdf` (requires `$postscript_mode = 1`)
- 3: uses `latex` + `dvipdf` (or `dvipdfm`/`dvipdfmx`, requires `$dvi_mode = 1`)
- 4: uses `lualatex` engine
- 5: uses `xelatex` engine

If no `.latexmkrc` file is found , we fall back to `pdflatex`. Note that `pdflatex` , `xelatex` , and `lualatex` require `postscript_mode` and `dvi_mode` to be set to zero.

## Hot Reloading

Hot reloading should be enabled by default for either Zathura or SumatraPDF (this config decides which to use depending on whether you're using Linux or Windows). Every time you write the file `:w` , Neovim will automatically invoke the compilation for whatever `pdf_mode` you have set and update the PDF.

## SVG Rendering

If you are using the `svg` package and want to do something like ,

```tex
\includesvg[width=0.8\textwidth]{assets/appendix/prism}
```

then you will need Inkscape installed on your system. The benefit of doing this is getting to see any edits you do to SVG files updated live on your PDF without needing to rerender them somewhere else separately.
