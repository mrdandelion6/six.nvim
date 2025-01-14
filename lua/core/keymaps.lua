-- buffer jumping
vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })
vim.keymap.set('n', '<C-x>', '<C-w><C-x>', { desc = 'Swap adjacent windows' })

-- clear highlights on search (? or /) when pressing <esc> in normal mode
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- diagnostics
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })

-- two <Esc> if you also use vim inside terminal itself (set -o vi)
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- disable yank for change operator. just use delete operator for cutting.
vim.keymap.set('n', 'c', '"_c')
vim.keymap.set('n', 'C', '"_C')
vim.keymap.set('v', 'c', '"_c')
vim.keymap.set('v', 'C', '"_C')

-- disable yank for x delete
vim.keymap.set('n', 'x', '"_x')

-- copy message
vim.keymap.set('n', '<leader>m', function()
  local msg = vim.fn.trim(vim.fn.execute '1messages')
  vim.fn.setreg('*', msg)
  vim.cmd 'echo "copied"'
end)
