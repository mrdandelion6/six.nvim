if not pcall(require, 'lualine') then
  return
end
MOST_RECENT_PWD = vim.fn.expand '~/.config/nvim/bash/recent_pwd.txt'

-- table of buf_num : bool
-- keeps track if we already created
local created_terminal_pwd_update = {}

print('A: table[buf] is ' .. tostring(created_terminal_pwd_update[19]))

local function create_terminal_pwd_update(buf)
  print('trigger 1. buf is ' .. buf)
  print('table[buf] is ' .. tostring(created_terminal_pwd_update[buf]))
  if not created_terminal_pwd_update[buf] then
    print 'trigger 2'
    vim.api.nvim_create_autocmd({ 'FileChangedShellPost' }, {
      pattern = MOST_RECENT_PWD,
      callback = function()
        print 'trigger 3'
        if vim.api.nvim_buf_is_valid(buf) then
          print 'cwd changed!!!'
          vim.api.nvim_buf_call(buf, function()
            print 'hi'
          end)
        end
      end,
    })
  end
  created_terminal_pwd_update[buf] = true
end

local function create_terminal_pwd_updates_for_all()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[buf].buftype == 'terminal' and vim.api.nvim_buf_is_valid(buf) then
      create_terminal_pwd_update(buf)
    end
  end
end

local term_upd_group = vim.api.nvim_create_augroup('autoload_cmd_lualine_updates', { clear = true })

print('B: table[buf] is ' .. tostring(created_terminal_pwd_update[19]))

vim.api.nvim_create_autocmd('TermOpen', {
  group = term_upd_group,
  callback = function(opts)
    create_terminal_pwd_update(opts.buf)
  end,
})

print('C: table[buf] is ' .. tostring(created_terminal_pwd_update[19]))

vim.api.nvim_create_autocmd('TermClose', {
  group = term_upd_group,
  callback = function(opts)
    created_terminal_pwd_update[opts.buf] = nil
  end,
})

print('D: table[buf] is ' .. tostring(created_terminal_pwd_update[19]))

vim.api.nvim_create_autocmd('VimEnter', {
  group = term_upd_group,
  callback = function()
    created_terminal_pwd_update = {}
    create_terminal_pwd_updates_for_all()
  end,
})

print('E: table[buf] is ' .. tostring(created_terminal_pwd_update[19]))
