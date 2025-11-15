vim.filetype.add {
  extension = {
    qmd = 'quarto',
    cu = 'cuda',
    cuh = 'cuda',
    -- HACK: change ths to hip once you have set up lsp support for it
    hip = 'cpp',
  },
}
