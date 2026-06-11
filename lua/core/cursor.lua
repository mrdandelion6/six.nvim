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
