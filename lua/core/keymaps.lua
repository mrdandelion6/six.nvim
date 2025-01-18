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

-- copy the most recent message
vim.api.nvim_set_keymap(
  'n',
  '<leader>mm',
  [[<cmd>lua vim.fn.setreg('*', vim.fn.trim(vim.fn.execute('1messages'))); vim.fn.setreg('+', vim.fn.trim(vim.fn.execute('1messages'))); print('copied')<CR>]],
  { noremap = true, silent = true, desc = 'Copy [M]ost recent [M]essage' }
)

-- create a new buffer with all the messages from :messages inside
vim.keymap.set('n', '<leader>mn', function()
  local buf = vim.api.nvim_create_buf(false, true)
  -- get messages and put into buffer
  local messages = vim.api.nvim_exec2('messages', { output = true }).output
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(messages, '\n'))
  -- open buffer in new window
  vim.cmd.split()
  vim.api.nvim_win_set_buf(0, buf)
  -- set buffer options
  vim.bo[buf].modifiable = false
  vim.bo[buf].buftype = 'nofile'
  vim.bo[buf].bufhidden = 'wipe'
end, { desc = 'Open [M]essages [N]ew buffer' })

-- COLEMAK-DH REMAPS
vim.g.colemak_enabled = false

-- function to toggle between layouts
local function toggle_colemak()
  if vim.g.colemak_enabled then
    -- remove colemak mappings, we are toggling colemak off
    vim.keymap.del({ 'n', 'v', 'o' }, 'n')
    vim.keymap.del({ 'n', 'v', 'o' }, 'e')
    vim.keymap.del({ 'n', 'v', 'o' }, 'i')
    vim.keymap.del({ 'n', 'v', 'o' }, 'o')
    vim.keymap.del({ 'n', 'v', 'o' }, 'N')
    vim.keymap.del({ 'n', 'v', 'o' }, 'E')
    vim.keymap.del({ 'n', 'v', 'o' }, 'I')
    vim.keymap.del({ 'n', 'v', 'o' }, 'O')
    vim.keymap.del({ 'n', 'v', 'o' }, 'h')
    vim.keymap.del({ 'n', 'v', 'o' }, 'j')
    vim.keymap.del({ 'n', 'v', 'o' }, 'k')
    vim.keymap.del({ 'n', 'v', 'o' }, 'l')
    vim.keymap.del({ 'n', 'v', 'o' }, 'H')
    vim.keymap.del({ 'n', 'v', 'o' }, 'J')
    vim.keymap.del({ 'n', 'v', 'o' }, 'K')
    vim.keymap.del({ 'n', 'v', 'o' }, 'L')
    vim.g.colemak_enabled = false
    print 'QWERTY layout enabled'
  else -- add colemakmappings, we are toggling it on
    -- note, (a -> b) means pressing b now does a
    for _, mode in ipairs { 'n', 'v', 'o' } do
      -- basic movement (hjkl -> neio)
      vim.keymap.set(mode, 'n', 'h', { desc = 'Move left' })
      vim.keymap.set(mode, 'e', 'j', { desc = 'Move down' })
      vim.keymap.set(mode, 'i', 'k', { desc = 'Move up' })
      vim.keymap.set(mode, 'o', 'l', { desc = 'Move right' })

      -- (HJLK -> NEIO) symmetrical
      vim.keymap.set(mode, 'N', 'H', { desc = 'Move to top of screen' })
      vim.keymap.set(mode, 'E', 'J', { desc = 'Join line' })
      vim.keymap.set(mode, 'O', 'L', { desc = 'Move to bottom of screen' })
      vim.keymap.set(mode, 'I', 'K', { desc = 'Keyword search' })

      -- (neio -> kjlh), not symmetrical!
      vim.keymap.set(mode, 'k', 'n', { desc = 'Next search result' })
      vim.keymap.set(mode, 'j', 'e', { desc = 'End of word' })
      vim.keymap.set(mode, 'l', 'i')
      vim.keymap.set(mode, 'h', 'o', { desc = 'Open line below' })

      -- (NEIO -> KJLH), not symmetrical!
      vim.keymap.set(mode, 'K', 'N', { desc = 'Previous search result' })
      vim.keymap.set(mode, 'J', 'E', { desc = 'End of WORD' })
      vim.keymap.set(mode, 'L', 'I', { desc = 'Enter insert mode at line start' })
      vim.keymap.set(mode, 'H', 'O', { desc = 'Open line above' })
    end
    vim.g.colemak_enabled = true
    print 'Colemak-DH layout enabled'
  end
end

-- create a command to toggle layouts
vim.api.nvim_create_user_command('ToggleColemak', toggle_colemak, {})
vim.api.keymap.set('n', '<leader>tc', ':ToggleColemak<CR>', { desc = '[T]oggle [C]olemak Layout' })
