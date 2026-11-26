local original_scrolloff = vim.o.scrolloff
function Center_cursor()
  if vim.b.scrolloff_processing then
    return
  end
  -- don't center in a terminal when the cursor is on its last line (nowhere
  -- further down to go), so the latest output stays at the bottom of the pane
  if vim.bo.buftype == 'terminal' and vim.fn.line '.' == vim.fn.line '$' then
    return
  end
  vim.b.scrolloff_processing = true

  vim.o.scrolloff = 0

  -- normal mode scrolls with zz: it shifts the screen and redraws only the new
  -- line , where winrestview redraws the whole window every move (~15ms in
  -- python / notebook buffers vs ~2ms). zz also centers past eof. run it on
  -- every move: the line-based offset below disagrees with zz's screen rows
  -- when lines wrap , so skipping on offset 0 left every other line off center.
  if vim.api.nvim_get_mode().mode == 'n' then
    vim.cmd 'normal! zz'
    vim.b.scrolloff_processing = false
    return
  end

  -- get cursor and window height
  local win_h = vim.api.nvim_win_get_height(0)
  local half_h = math.floor(win_h / 2)
  local cursor_h = vim.fn.line '.' - vim.fn.line 'w0' + 1

  -- get offset
  local offset = cursor_h - half_h

  -- apply offset. other modes keep winrestview since :normal there can end
  -- visual mode or nudge the cursor at the end of a line. skipped when already
  -- centered (ex. typing along a line in insert mode).
  if offset ~= 0 then
    local win_view = vim.fn.winsaveview()
    win_view.skipcol = 0
    win_view.topline = win_view.topline + offset
    vim.fn.winrestview(win_view)
  end

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
