vim.cmd 'command! -nargs=1 Vr vertical resize <args>'
vim.cmd 'command! -nargs=1 Hr horizontal resize <args>'
vim.api.nvim_create_user_command('Yp', function()
  local path = vim.fn.expand '%:p:h'
  vim.fn.setreg('+', path)
  print('Yanked: ' .. path)
end, {})

-- TODO: add commands and keymaps for C++ compilation
