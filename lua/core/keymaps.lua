-- buffer jumping
local function buf_jump_set(set, remove)
  -- set: a 4 letter string like 'knei' or 'hjkl'
  -- remove: same as above but can be nil
  -- this function sets the buffer jumps to be the letters of set (left, down, up, right respectively)
  -- and also removes the keybinds in remove
  if remove ~= nil then
    for i = 1, 4 do
      local c = remove:sub(i, i)
      pcall(vim.keymap.del, 'n', '<C-' .. c .. '>')
    end
  end
  local c = set:sub(1, 1)
  vim.keymap.set('n', '<C-' .. c .. '>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
  c = set:sub(2, 2)
  vim.keymap.set('n', '<C-' .. c .. '>', '<C-w><C-j>', { desc = 'Move focus to the bottom window' })
  c = set:sub(3, 3)
  vim.keymap.set('n', '<C-' .. c .. '>', '<C-w><C-k>', { desc = 'Move focus to the top window' })
  c = set:sub(4, 4)
  vim.keymap.set('n', '<C-' .. c .. '>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
end

local function set_telescope_binds(binds)
  vim.g.telescope_maps = binds
  local telescope_loaded = pcall(function()
    return require('lazy.core.config').plugins['telescope.nvim'].loaded
  end)
  if telescope_loaded then
    vim.cmd 'doautocmd User TelescopeMapsChanged'
  else
    vim.api.nvim_create_autocmd('User', {
      pattern = 'TelescopeLoaded',
      callback = function()
        vim.cmd 'doautocmd User TelescopeMapsChanged'
      end,
      once = true,
    })
  end
end

local function set_layout_persistence(new_layout)
  local layout_path = vim.fn.stdpath 'config' .. '/.localsettings.json'
  local settings = {}

  local file = io.open(layout_path, 'r')
  if file then
    local content = file:read '*a'
    file:close()
    local ok, parsed = pcall(vim.fn.json_decode, content)
    if ok and type(parsed) == 'table' then
      settings = parsed
    else
      print('could not parse an existing settings file at: ' .. layout_path)
    end
  end

  settings.layout = new_layout
  local settings_json = { vim.fn.json_encode(settings) }
  local success = pcall(function()
    return vim.fn.writefile(settings_json, layout_path)
  end)
  if not success then
    print('failed to update persistence for keyboard layout at: ' .. layout_path)
  end
end

local function enable_colemak()
  local remaps = {
    ['k'] = 'h',
    ['n'] = 'j',
    ['e'] = 'k',
    ['i'] = 'l',

    ['K'] = 'H',
    ['N'] = 'J',
    ['E'] = 'K',
    ['I'] = 'L',

    -- notice, these are not symmetrical to above
    ['h'] = 'n',
    ['j'] = 'e',
    ['l'] = 'i',

    ['H'] = 'N',
    ['J'] = 'E',
    ['L'] = 'I',
  }
  -- ALL MODES
  for _, mode in ipairs { 'n', 'v', 'o' } do
    vim.keymap.set(mode, 'k', remaps['k'], { desc = 'Left' })
    vim.keymap.set(mode, 'n', remaps['n'], { desc = 'Down' })
    vim.keymap.set(mode, 'e', remaps['e'], { desc = 'Up' })
    vim.keymap.set(mode, 'i', remaps['i'], { desc = 'Right' })

    -- (HJLK -> KNEI)
    vim.keymap.set(mode, 'K', remaps['K'], { desc = 'Top of screen' })
    vim.keymap.set(mode, 'I', remaps['I'], { desc = 'Bottom of screen' })

    -- (knei -> ehjl), not symmetrical!
    vim.keymap.set(mode, 'j', remaps['j'], { desc = 'End of word' })

    -- (NEIO -> KJLH), not symmetrical!
    vim.keymap.set(mode, 'J', remaps['J'], { desc = 'End of next word' })
  end

  -- NORMAL AND VISUAL MODE
  for _, mode in ipairs { 'n', 'v' } do
    vim.keymap.set(mode, 'N', remaps['J'], { desc = 'Join line' })
    vim.keymap.set(mode, 'E', remaps['E'], { desc = 'Keyword search' })

    vim.keymap.set(mode, 'h', remaps['h'], { desc = 'Next search result' })
    vim.keymap.set(mode, 'H', remaps['H'], { desc = 'Previous search result' })
    vim.keymap.set(mode, 'L', remaps['L'], { desc = 'Insert mode at line start' })
  end

  -- NORMAL MODE ONLY
  vim.keymap.set('n', 'l', remaps['l'], { desc = 'Insert mode' })

  -- OPERATOR MODE ONLY
  vim.keymap.set('o', 'l', remaps['l'], { desc = 'Inner' })

  buf_jump_set('knei', 'hjkl')
  -- return to next position
  vim.keymap.set('n', '<C-l>', '<C-i>')

  -- set telescope to colemak mappings
  local telescope_maps = {
    i = {
      ['<C-n>'] = 'move_selection_next',
      ['<C-e>'] = 'move_selection_previous',
    },
    n = {
      ['n'] = 'move_selection_next',
      ['e'] = 'move_selection_previous',
    },
  }
  set_telescope_binds(telescope_maps)

  vim.g.VM_maps = {
    ['Find Under'] = '<Leader>ah',
    ['Find Subword Under'] = '<Leader>ah',
    ['Add Cursor Down'] = '<Leader>an',
    ['Add Cursor Up'] = '<Leader>ae',
    ['Next'] = 'h',
    ['Prev'] = 'H',
  }

  -- set persistence in .localsettings.json
  set_layout_persistence 'colemak'
  local settings = vim.g.local_settings
  settings.layout = 'colemak'
  vim.g.local_settings = settings
  print 'Colemak-DH layout enabled'
end

local function enable_qwerty(startup)
  -- remove colemak mappings, we are toggling colemak off
  if not startup then
    -- we could just set the keymaps to avoid startup check but i find this cleaner since we don't need to add any descriptions
    vim.keymap.del({ 'n', 'v', 'o' }, 'k')
    vim.keymap.del({ 'n', 'v', 'o' }, 'n')
    vim.keymap.del({ 'n', 'v', 'o' }, 'e')
    vim.keymap.del({ 'n', 'v', 'o' }, 'i')
    vim.keymap.del({ 'n', 'v', 'o' }, 'K')
    vim.keymap.del({ 'n', 'v' }, 'N')
    vim.keymap.del({ 'n', 'v' }, 'E')
    vim.keymap.del({ 'n', 'v', 'o' }, 'I')
    vim.keymap.del({ 'n', 'v' }, 'h')
    vim.keymap.del({ 'n', 'v', 'o' }, 'j')
    vim.keymap.del({ 'n', 'o' }, 'l')
    vim.keymap.del({ 'n', 'v' }, 'H')
    vim.keymap.del({ 'n', 'v', 'o' }, 'J')
    vim.keymap.del({ 'n', 'v' }, 'L')
  end

  buf_jump_set('hjkl', 'knei')

  -- set telescope to default qwerty mappings
  local telescope_maps = {
    i = {
      ['<C-j>'] = 'move_selection_next',
      ['<C-k>'] = 'move_selection_previous',
    },
    n = {
      ['j'] = 'move_selection_next',
      ['k'] = 'move_selection_previous',
    },
  }
  set_telescope_binds(telescope_maps)

  -- set vim-visual-multi maps
  vim.g.VM_maps = {
    ['Find Under'] = '<Leader>an',
    ['Find Subword Under'] = '<Leader>an',
    ['Add Cursor Down'] = '<Leader>aj',
    ['Add Cursor Up'] = '<Leader>ak',
    ['Next'] = 'n',
    ['Prev'] = 'N',
  }

  set_layout_persistence 'qwerty'
  local settings = vim.g.local_settings
  settings.layout = 'qwerty'
  vim.g.local_settings = settings
  print 'QWERTY layout enabled'
end

local function start_layout()
  --[[
  this function checks a file: .localsettings.json in the nvim config directory to determine what keyboard layout to start with.
  the.localsettings.json file is expected to be of the format:
    {
      "layout": "colemak",
      ... other settings
    }
  or alternatively, "qwerty".
  ]]

  -- check if settings is in right format
  local settings = vim.g.local_settings
  if not settings then
    print 'ERROR: vim.g.local_settings is nil'
    return
  end
  if not settings.layout then
    print 'ERROR: parsing vim.g.local_settings: layout key is nil'
    return
  end

  if settings.layout == 'colemak' then
    -- colemak
    enable_colemak()
  elseif settings.layout == 'qwerty' then
    -- qwerty
    enable_qwerty(1)
  else
    print('unexpected settings layout: ' .. settings.layout)
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
    'n',          -- normal mode
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

-- leader <Esc> if you also use vim inside terminal itself (set -o vi)
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

start_layout()
set_message_maps()
disable_yanks()

-- function to toggle between layouts
local function toggle_colemak()
  local settings = vim.g.local_settings
  if settings.layout == 'colemak' then
    enable_qwerty()
  elseif settings.layout == 'qwerty' then -- add colemak mappings, we are toggling it on
    enable_colemak()
  else
    print('unexpected settings layout: ' .. settings.layout)
  end
end

-- create a command to toggle layouts
vim.api.nvim_create_user_command('ToggleColemak', toggle_colemak, {})
vim.keymap.set('n', '<leader>tc', ':ToggleColemak<CR>', { desc = '[T]oggle [C]olemak Layout' })
