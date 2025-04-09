vim.cmd 'command! -nargs=1 Vr vertical resize <args>'
vim.api.nvim_create_user_command('Ww', function()
  -- write without autoformat
  local prev_state = vim.g.format_on_save
  vim.g.format_on_save = false
  vim.cmd 'write'
  vim.g.format_on_save = prev_state
end, {})
