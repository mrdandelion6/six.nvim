return {
  'nvim-lualine/lualine.nvim',
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  config = function()
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
      vim.b[buf].terminal_pwd = '' -- buffer local variable
      if not created_terminal_pwd_update[buf] then
        vim.api.nvim_create_autocmd({ 'TermRequest' }, {
          buffer = buf,
          callback = function()
            local pwd = parse_terminal_request(vim.v.termrequest)
            if vim.api.nvim_buf_is_valid(buf) then
              vim.b[buf].terminal_pwd = pwd -- store pwd in bufer local variable
              vim.api.nvim_buf_call(buf, function()
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

    local default_b = { fg = '#000000', bg = '#cccccc' }

    require('lualine').setup {
      options = {
        component_separators = '',
        section_separators = '',
        globalstatus = false, -- this allows the bar to split in the middle
        theme = {
          normal = {
            a = { fg = '#000000', bg = '#f0a4d0' }, -- teal for normal
            b = default_b,
            c = { fg = '#ffffff', bg = 'NONE' },
          },
          insert = {
            a = { fg = '#000000', bg = '#7bd5af' }, -- pink for insert
            b = default_b,
            c = { fg = '#ffffff', bg = 'NONE' },
          },
          visual = {
            a = { fg = '#000000', bg = '#87ceeb' }, -- light blue for visual
            b = default_b,
            c = { fg = '#ffffff', bg = 'NONE' },
          },
          replace = {
            a = { fg = '#000000', bg = '#ffb6c1' }, -- light red for replace
            b = default_b,
            c = { fg = '#ffffff', bg = 'NONE' },
          },
        },
      },
      sections = {
        lualine_a = {
          {
            'mode',
            fmt = function(str)
              return str:sub(1, 1) -- show only first letter of mode
            end,
            padding = { left = 1, right = 1 },
            separator = {
              right = (function()
                local root = Get_git_root()
                local sep = (root == '') and '' or ''
                -- if vim.api.nvim_get_current_buf() == 3 then
                -- print("Git root value: '" .. tostring(root) .. "'")
                -- print("Separator value: '" .. tostring(sep) .. "'")
                -- end
                return sep
              end)(),
            },
          },
        },

        lualine_b = {
          {
            separator = { right = '' },
            padding = { left = 1, right = 1 },
            Get_git_root,
            cond = function()
              return vim.bo.buftype == '' and vim.fn.expand '%:p' ~= ''
            end,
          },
        },

        lualine_c = {
          {
            'filename',
            path = 1,
            file_status = true,
            fmt = function(name) -- for terminal, display path of termrinal
              if vim.bo.buftype == 'terminal' then
                local buf = vim.api.nvim_get_current_buf()
                -- use the local buffer pwd which we set in after/plugin/lualine.lua
                if vim.b[buf].terminal_pwd and vim.b[buf].terminal_pwd ~= '' then
                  return vim.b[buf].terminal_pwd
                end
                return vim.b.term_title:match 'term://(.-)//' or name
              end
              return name
            end,
            padding = { left = 1, right = 1 },
          },
        },

        lualine_x = {},
        lualine_y = {},
        lualine_z = {
          {
            separator = { left = '' },
            'location', -- show line/column numbers
            padding = { left = 1, right = 1 },
          },
        },
      },
      inactive_sections = {
        lualine_c = {
          {
            'filename',
            path = 1,
            file_status = true,
            fmt = function(name) -- for terminal, display path of termrinal
              if vim.bo.buftype == 'terminal' then
                local buf = vim.api.nvim_get_current_buf()
                -- use the local buffer pwd which we set in after/plugin/lualine.lua
                if vim.b[buf].terminal_pwd and vim.b[buf].terminal_pwd ~= '' then
                  return vim.b[buf].terminal_pwd
                end
                return vim.b.term_title:match 'term://(.-)//' or name
              end
              return name
            end,
            padding = { left = 1, right = 1 },
          },
        },
      },
    }
    vim.opt.termguicolors = true
  end,
}
