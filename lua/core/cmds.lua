-- NOTE: this file contains both autocommands and commands for core/ features.
-- for autocommands that interact with plugins , see the lua files for those
-- specific plugins.
local utils = require 'core.utils'

-- VIMENTER (runs once on startup)
vim.api.nvim_create_autocmd('VimEnter', {
  once = true,
  callback = function()
    vim.g.start_dir = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ':p:h')
  end,
})

-- PANE
vim.cmd 'command! -nargs=1 Vr vertical resize <args>'
vim.cmd 'command! -nargs=1 Hr horizontal resize <args>'

-- TEXT
-- yank path of current buffer
vim.api.nvim_create_user_command('Yp', function()
  local path = vim.fn.expand '%:p:h'
  vim.fn.setreg('+', path)
  print('Yanked path: ' .. path)
end, {})

-- highlight when yanking (copying) text
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})

-- GIT
vim.api.nvim_create_autocmd({ 'BufEnter' }, {
  callback = function()
    vim.g.git_root = utils.get_git_root()
  end,
})

-- TODO: add commands and keymaps for C++ compilation
