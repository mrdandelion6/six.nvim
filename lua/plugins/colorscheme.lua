return {
  'catppuccin/nvim',
  name = 'catppuccin',
  priority = 1000,
  init = function()
    require('catppuccin').setup {
      transparent_background = true,
      -- You can choose flavors:
      -- 'mocha' (dark), 'macchiato', 'frappe', 'latte' (light)
      flavour = 'mocha',
      custom_highlights = {

        -- Pallete:
        -- light grey
        -- light green
        -- light blue
        -- light red
        -- light pink
        -- strong pink
        -- strong blue
        -- strong purple
        -- light orange

        ['@variable'] = { fg = '#aad3fa' },
        ['@property'] = { fg = '#fe9df3' },
        ['@field'] = { fg = '#fe9df3' },
        ['@constant'] = { fg = '#a66bf0' },

        ['@function'] = { fg = '#89b4fa' },
        ['@parameter'] = { fg = '#eaa658' },
        ['@function.builtin'] = { fg = '#f5a787' },
        ['@keyword.return'] = { fg = '#ff6dba' },

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
