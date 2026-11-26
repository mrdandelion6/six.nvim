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

local function open_term_in_split()
  local platform = require 'core.platform'
  local args = vim.fn.argv()

  vim.cmd 'vsplit | wincmd l'
  local ratio = 0.45
  if platform.is_windows() then
    -- terminals spawned inside windows for nvim cant shrink fastfetch
    -- output for some reason , so need more space.
    ratio = 0.52
  end
  local width = math.floor(vim.o.columns * ratio)
  vim.cmd('vertical resize ' .. width .. ' | terminal')
  vim.cmd 'startinsert'
end

vim.api.nvim_create_user_command('Vst', open_term_in_split, {})

-- TEXT
-- yank path of current buffer
vim.api.nvim_create_user_command('Yp', function()
  local path = vim.fn.expand '%:p:h'
  vim.fn.setreg('+', path)
  print('Yanked path: ' .. path)
end, { desc = 'Yank path the buffer lives in' })

-- yank full path of current file
vim.api.nvim_create_user_command('Yf', function()
  local path = vim.fn.expand '%:p'
  vim.fn.setreg('+', path)
  print('Yanked file path: ' .. path)
end, { desc = 'Yank full path of the current file' })

-- highlight when yanking (copying) text
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})

-- GIT
-- DirChanged: buffers without a file (empty, help, ...) use the cwd's repo
vim.api.nvim_create_autocmd({ 'BufEnter', 'DirChanged' }, {
  callback = function()
    vim.g.git_root = utils.get_git_root()
  end,
})

-- open the real file when editing a symlink (so fugitive/gitsigns see the repo)
vim.api.nvim_create_autocmd('BufReadPost', {
  desc = 'Resolve symlinks to their real path',
  group = vim.api.nvim_create_augroup('resolve_symlinks', { clear = true }),
  callback = function(ev)
    local path = vim.api.nvim_buf_get_name(ev.buf)
    local real = vim.uv.fs_realpath(path)
    if real and real ~= path then
      vim.schedule(function()
        vim.cmd('keepalt edit ' .. vim.fn.fnameescape(real))
        pcall(vim.cmd, 'bwipeout ' .. ev.buf)
      end)
    end
  end,
})

-- reload files changed outside nvim (ex. by claude code running in a :terminal
-- here). autoread alone only checks on FocusGained , which never fires when
-- switching between nvim windows. :e would also reload , but it unloads the
-- buffer , which drops molten's kernel
vim.api.nvim_create_autocmd({ 'FocusGained', 'WinEnter', 'BufEnter', 'CursorHold', 'CursorHoldI' }, {
  desc = 'Reload files changed on disk',
  group = vim.api.nvim_create_augroup('auto_checktime', { clear = true }),
  callback = function()
    if vim.fn.mode() ~= 'c' and vim.fn.getcmdwintype() == '' then
      vim.cmd 'checktime'
    end
  end,
})

-- line numbers in :terminal windows. nvim's default TermOpen autocmd turns them
-- off in terminals , so turn them back on. always on , since toggling them by
-- mode changed the terminal's width on every switch and the program in it
-- (ex. claude code) redrew and jumped around. relative numbers only , since
-- with number on the column fits the largest absolute line , and terminals keep
-- up to 10000 lines of scrollback (6 columns). relative numbers only go up to
-- the window height , so the column stays at numberwidth (4)
vim.api.nvim_create_autocmd('TermOpen', {
  desc = 'Show relative line numbers in terminals',
  group = vim.api.nvim_create_augroup('term_numbers', { clear = true }),
  callback = function()
    vim.wo.number = false
    vim.wo.relativenumber = true
  end,
})

-- TODO: add commands and keymaps for C++ compilation
