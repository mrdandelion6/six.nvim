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

local utils = require 'core.utils'

vim.api.nvim_create_autocmd({ 'BufEnter' }, {
  callback = function()
    vim.g.git_root = utils.get_git_root()
  end,
})

vim.api.nvim_create_user_command('DisableFormatting', function()
  local bufnr = vim.api.nvim_get_current_buf()

  -- disable lsp formatting capabilities for this buffer only
  vim.b.disable_formatting = true

  -- get all attached clients for this buffer
  local clients = vim.lsp.get_clients { buffer = bufnr }
  for _, client in ipairs(clients) do
    client.server_capabilities.documentFormattingProvider = false
    client.server_capabilities.documentRangeFormattingProvider = false
  end

  print 'Formatting disabled for current buffer'
end, {})

-- always center
local original_scrolloff = vim.o.scrolloff
function Center_cursor()
  if vim.b.scrolloff_processing then
    return
  end
  vim.b.scrolloff_processing = true

  -- get cursor and window height
  vim.o.scrolloff = 0
  local win_h = vim.api.nvim_win_get_height(0)
  local half_h = math.floor(win_h / 2)
  local cursor_h = vim.fn.line '.' - vim.fn.line 'w0' + 1

  -- get offset
  local offset = cursor_h - half_h

  -- apply offset
  local win_view = vim.fn.winsaveview()
  win_view.skipcol = 0
  win_view.topline = win_view.topline + offset
  vim.fn.winrestview(win_view)

  vim.b.scrolloff_processing = false
end

vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI', 'BufEnter' }, {
  group = vim.api.nvim_create_augroup('ScrollOffEOF', {}),
  callback = Center_cursor,
})

-- important for things like undo command.
vim.api.nvim_create_autocmd('TextChanged', {
  callback = Center_cursor,
})
