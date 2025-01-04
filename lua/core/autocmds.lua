--  since we use ctrl+<hjkl> to switch between windows
--  need to first free <C-l> from netrw. we delete it.
--  netrw (built in tool of vim) is what we are currently used for file tree.
--  one of netrw's commands is <C-l> which we need for moving to right split.
vim.api.nvim_create_autocmd('FileType', {
  pattern = 'netrw',
  callback = function()
    pcall(function()
      vim.keymap.del('n', '<C-l>', { buffer = true })
    end)
  end,
})

-- highlight when yanking (copying) text
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})
