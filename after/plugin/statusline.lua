if not pcall(require, 'lualine') then
  return
end
MOST_RECENT_PWD = vim.fn.expand '~/.config/nvim/bash/recent_pwd.txt'

-- table of buf_num : bool
-- keeps track if we already created
local created_terminal_pwd_update = {}

local function parse_terminal_request(request)
  -- the bash code that sends terminal requests with OSC is as follows:
  --  printf '\033]51;%s\007' $(pwd)
  -- i have tried many other variations as well, but was not able to get a clean transfer of json or string.
  -- the requests (collected with vim.v.termrequest), end up having some leading characters.
  -- to make a quick work around for this with my current config, i am just going to splice them off.
  -- hopefully one day i can figure out how to properly send/read the OSC requests so i don't need abitrary cleaning like this.
  local cleaned = request:sub(6)
  cleaned = cleaned:gsub('^/home/[^/]+/', '~/')
  return cleaned
end

local function create_terminal_pwd_update(buf)
  print('trigger 1. buf is ' .. buf)
  print('table[' .. buf .. '] is ' .. tostring(created_terminal_pwd_update[buf]))
  vim.b[buf].terminal_pwd = '' -- buffer local variable
  if not created_terminal_pwd_update[buf] then
    print 'trigger 2'
    vim.api.nvim_create_autocmd({ 'TermRequest' }, {
      buffer = buf,
      callback = function()
        local pwd = parse_terminal_request(vim.v.termrequest)
        print('trigger 3, request is: ' .. pwd)
        if vim.api.nvim_buf_is_valid(buf) then
          print 'trigger 4'
          vim.b[buf].terminal_pwd = pwd -- store pwd in bufer local variable
          vim.api.nvim_buf_call(buf, function()
            print 'trigger 5'
            vim.cmd 'redrawstatus!'
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

vim.api.nvim_create_autocmd('TermOpen', {
  group = term_upd_group,
  callback = function(opts)
    create_terminal_pwd_update(opts.buf)
  end,
})

vim.api.nvim_create_autocmd('TermClose', {
  group = term_upd_group,
  callback = function(opts)
    created_terminal_pwd_update[opts.buf] = nil
  end,
})

vim.api.nvim_create_autocmd('VimEnter', {
  group = term_upd_group,
  callback = function()
    created_terminal_pwd_update = {}
    create_terminal_pwd_updates_for_all()
  end,
})
