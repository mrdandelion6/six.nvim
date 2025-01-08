return {
  'catppuccin/nvim',
  name = 'catppuccin',
  priority = 1000,
  init = function()
    -- Pallete:
    local light_grey = ''
    -- light green
    local light_blue = '#aad3fa'
    -- light red
    -- light pink
    local strong_pink = '#fe9df3'
    local vibrant_pink = '#ff6dba'
    local strong_blue = '#89b4fa'
    local strong_purple = '#a66bf0'
    local light_orange = '#f5b579'
    local strong_orange = '#eaa658'

    require('catppuccin').setup {
      transparent_background = true,
      -- You can choose flavors:
      -- 'mocha' (dark), 'macchiato', 'frappe', 'latte' (light)
      flavour = 'mocha',
      custom_highlights = {

        ['@variable'] = { fg = light_blue },
        ['@property'] = { fg = strong_pink },
        ['@field'] = { fg = strong_pink },
        ['@constant'] = { fg = strong_purple },

        ['@function'] = { fg = strong_blue },
        ['@parameter'] = { fg = strong_orange },
        ['@function.builtin'] = { fg = light_orange },
        ['@keyword.return'] = { fg = vibrant_pink },

        ['@type'] = { fg = '#7ac4ff' },
        ['@keyword'] = { fg = '#d594ff' },

        ['@keyword.function'] = { fg = '#d594ff' },
        ['@keyword.repeat'] = { fg = '#f5a787' },
        ['@keyword.conditional'] = { fg = '#ffb0ff' },

        ['@string'] = { fg = '#de80a1' },
        ['@comment'] = { fg = '#c4bdd2' },

        ['@operator'] = { fg = '#d5dae1' },

        -- Primitives
        ['@boolean'] = { fg = '#f5c287' },
        ['@number'] = { fg = '#f5c287' },
      },
    }
    vim.cmd.colorscheme 'catppuccin'
  end,
}
