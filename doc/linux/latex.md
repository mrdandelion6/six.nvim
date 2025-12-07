# LaTeX

## deps

you will need:

- pdflatex
- zathura for linux
- SumatraPDF for windows

## Snippets

to make snippets for a filetype `ft` , edit `snippets/ft.lua`. for example , for c++ snippets , you can edit `snippets/cpp.lua`.

## custom compilation

for custom compilation commands , create a `.latexmkrc` file in the same directory as the `.tex` file. you can configure this file to achieve things like using other latex compilers and passing arguments to said compilers.

### XeLaTeX

since you will usually use `pdflatex` , that is the default compiler without any `.latexmkrc` file configured. if you want to use other compilers such as `xelatex` , edit `.latexmkrc` as follows ,

```bash
$pdf_mode = 5; # uses xelatex
$postscript_mode = 0;
$dvi_mode = 0;
```

### other compilers

here are what the different values for `pdf_mode` change for the compilation process:

- 1: uses `pdflatex` engine
- 2: uses `latex` + `dvips` + `ps2pdf` (requires `$postscript_mode = 1`)
- 3: uses `latex` + `dvipdf` (or `dvipdfm`/`dvipdfmx`, requires `$dvi_mode = 1`)
- 4: uses `lualatex` engine
- 5: uses `xelatex` engine

if no `.latexmkrc` file is found , we fall back to `pdflatex`. note that `pdflatex` , `xelatex` , and `lualatex` require `postscript_mode` and `dvi_mode` to be set to zero.

## hot reloading

hot reloading should be enabled by default for either zathura or SumatraPDF (this config decides which to use depending on whether you're using linux or windows). every time you write the file `:w` , neovim will automatically invoke the compilation for whatever `pdf_mode` you have set and update the pdf.

## SVG rendering

if you are using the `svg` package and want to do something like ,

```tex
\includesvg[width=0.8\textwidth]{assets/appendix/prism}
```

then you will need Inkscape installed on your system. the benefit of doing this is getting to see any edits you do to SVG files updated live on your PDF without needing to rerender them somewhere else separately.
