-- buffer jumping
local function buf_jump_set(set, remove)
  -- set: a 4 letter string like 'knei' or 'hjkl'
  -- remove: same as above but can be nil
  -- this function sets the buffer jumps to be the letters of set (left, down, up, right respectively)
  -- and also removes the keybinds in remove
  if remove ~= nil then
    for i = 1, 4 do
      local c = remove:sub(i, i)
      pcall(vim.keymap.del, 'n', 'c')
    end
    local c = set:sub(1, 1)
    vim.keymap.set('n', '<C-' .. c .. '>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
    c = set:sub(2, 2)
    vim.keymap.set('n', '<C-' .. c .. '>', '<C-w><C-j>', { desc = 'Move focus to the left window' })
    c = set:sub(3, 3)
    vim.keymap.set('n', '<C-' .. c .. '>', '<C-w><C-k>', { desc = 'Move focus to the left window' })
    c = set:sub(4, 4)
    vim.keymap.set('n', '<C-' .. c .. '>', '<C-w><C-l>', { desc = 'Move focus to the left window' })
  end
end

local function enable_colemak()
  -- note, (a -> b) means pressing b now does a
  for _, mode in ipairs { 'n', 'v', 'o' } do
    -- basic movement (hjkl -> knei)
    vim.keymap.set(mode, 'k', 'h', { desc = 'Move left' })
    vim.keymap.set(mode, 'n', 'j', { desc = 'Move down' })
    vim.keymap.set(mode, 'e', 'k', { desc = 'Move up' })
    vim.keymap.set(mode, 'i', 'l', { desc = 'Move right' })

    -- (HJLK -> KNEI)
    vim.keymap.set(mode, 'K', 'H', { desc = 'Move to top of screen' })
    vim.keymap.set(mode, 'N', 'J', { desc = 'Join line' })
    vim.keymap.set(mode, 'E', 'K', { desc = 'Keyword search' })
    vim.keymap.set(mode, 'I', 'L', { desc = 'Move to bottom of screen' })

    -- (knei -> ehjl), not symmetrical!
    vim.keymap.set(mode, 'h', 'n', { desc = 'Next search result' })
    vim.keymap.set(mode, 'j', 'e', { desc = 'End of word' })
    vim.keymap.set(mode, 'l', 'i', { desc = 'Insert mode' })

    -- (NEIO -> KJLH), not symmetrical!
    vim.keymap.set(mode, 'H', 'N', { desc = 'Previous search result' })
    vim.keymap.set(mode, 'J', 'E', { desc = 'End of WORD' })
    vim.keymap.set(mode, 'L', 'I', { desc = 'Enter insert mode at line start' })
  end

  buf_jump_set('knei', 'hjkl')

  -- set telescope to colemak mappings
  require('telescope').setup {
    defaults = {
      mappings = {
        i = {
          ['<C-n>'] = 'move_selection_next',
          ['<C-e>'] = 'move_selection_previous',
        },
        n = {
          ['n'] = 'move_selection_next',
          ['e'] = 'move_selection_previous',
        },
      },
    },
  }

  vim.g.VM_maps = {
    ['Find Under'] = '<Leader>ah',
    ['Find Subword Under'] = '<Leader>ah',
    ['Add Cursor Down'] = '<Leader>an',
    ['Add Cursor Up'] = '<Leader>ae',
    ['Next'] = 'h',
    ['Prev'] = 'H',
  }

  vim.g.colemak_enabled = true
  print 'Colemak-DH layout enabled'
end

local function disable_colemak()
  -- remove colemak mappings, we are toggling colemak off
  vim.keymap.del({ 'n', 'v', 'o' }, 'k')
  vim.keymap.del({ 'n', 'v', 'o' }, 'n')
  vim.keymap.del({ 'n', 'v', 'o' }, 'e')
  vim.keymap.del({ 'n', 'v', 'o' }, 'i')
  vim.keymap.del({ 'n', 'v', 'o' }, 'K')
  vim.keymap.del({ 'n', 'v', 'o' }, 'N')
  vim.keymap.del({ 'n', 'v', 'o' }, 'E')
  vim.keymap.del({ 'n', 'v', 'o' }, 'I')
  vim.keymap.del({ 'n', 'v', 'o' }, 'h')
  vim.keymap.del({ 'n', 'v', 'o' }, 'j')
  vim.keymap.del({ 'n', 'v', 'o' }, 'l')
  vim.keymap.del({ 'n', 'v', 'o' }, 'H')
  vim.keymap.del({ 'n', 'v', 'o' }, 'J')
  vim.keymap.del({ 'n', 'v', 'o' }, 'L')

  buf_jump_set('hjkl', 'knei')

  -- reset telescope to default qwerty mappings
  require('telescope').setup {
    defaults = {
      mappings = {
        i = {
          ['<C-j>'] = 'move_selection_next',
          ['<C-k>'] = 'move_selection_previous',
        },
        n = {
          ['j'] = 'move_selection_next',
          ['k'] = 'move_selection_previous',
        },
      },
    },
  }

  vim.g.VM_maps = {
    ['Find Under'] = '<Leader>an',
    ['Find Subword Under'] = '<Leader>an',
    ['Add Cursor Down'] = '<Leader>aj',
    ['Add Cursor Up'] = '<Leader>ak',
    ['Next'] = 'n',
    ['Prev'] = 'N',
  }

  vim.g.colemak_enabled = false
  print 'QWERTY layout enabled'
end

local function start_layout()
  -- TODO: add persistence
  vim.g.colemak_enabled = false
  if vim.g.colemak_enabled then
    enable_colemak()
  end
end

local function disable_yanks()
  -- disable yank for change operator. just use delete operator for cutting.
  vim.keymap.set('n', 'c', '"_c')
  vim.keymap.set('n', 'C', '"_C')
  vim.keymap.set('v', 'c', '"_c')
  vim.keymap.set('v', 'C', '"_C')

  -- disable yank for del
  vim.keymap.set('n', '<Del>', '"_<Del>')
end

local function set_message_maps()
  -- copy the most recent message
  vim.api.nvim_set_keymap(
    'n', -- normal mode
    '<leader>mm', -- key combination
    "<cmd>lua require('core.utils').Copy_recent_message()<CR>",
    {
      noremap = true,
      silent = true,
      desc = 'Copy [M]ost recent [M]essage',
    }
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
end

-- GENERAL
-- clear highlights on search (? or /) when pressing <esc> in normal mode
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- diagnostics
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })

-- two <Esc> if you also use vim inside terminal itself (set -o vi)
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

start_layout()
set_message_maps()
disable_yanks()

-- function to toggle between layouts, export for autocmds.lua
local M = {}
function M.toggle_colemak()
  if vim.g.colemak_enabled then
    disable_colemak()
  else -- add colemak mappings, we are toggling it on
    enable_colemak()
  end
end

return M
