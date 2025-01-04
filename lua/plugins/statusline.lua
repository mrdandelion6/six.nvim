return {
  'nvim-lualine/lualine.nvim',
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  config = function()
    local default_b = { fg = '#000000', bg = '#cccccc' }

    require('lualine').setup {
      options = {
        component_separators = '',
        section_separators = '',
        globalstatus = false, -- this allows the bar to split in the middle
        theme = {
          normal = {
            a = { fg = '#000000', bg = '#7bd5af' }, -- teal for normal
            b = default_b,
            c = { fg = '#ffffff', bg = 'NONE' },
          },
          insert = {
            a = { fg = '#000000', bg = '#f0a4d0' }, -- pink for insert
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
          },
        },
        lualine_b = {}, -- empty to allow split

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
            'location', -- show line/column numbers
            padding = { left = 1, right = 1 },
          },
        },
      },
    }
    vim.opt.termguicolors = true
  end,
}
