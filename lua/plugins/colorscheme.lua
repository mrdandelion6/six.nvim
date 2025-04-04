return {
  {
    'catppuccin/nvim',
    name = 'catppuccin',
    priority = 1000,
    init = function()
      -- Pallete:
      local white = '#d5dae1'
      local grey = '#c4bdd2'

      local light_yellow = '#f5c287'

      local light_orange = '#f5b579'
      local strong_orange = '#eaa658'

      local lighter_red = '#e89bb6'
      local light_red = '#de80a1'
      local vibrant_red = '#ff5f83'

      local lighter_pink = '#ffddff'
      local light_pink = '#ffb0ff'
      local strong_pink = '#fe89f3'
      local vibrant_pink = '#ff6dba'

      local light_purple = '#a6b2fc'
      local strong_purple = '#a68cf0'

      local light_blue = '#aad3fa'
      local strong_blue = '#89b4fa'

      require('catppuccin').setup {
        transparent_background = true,
        -- you can choose flavors:
        -- 'mocha' (dark), 'macchiato', 'frappe', 'latte' (light)
        flavour = 'mocha',
        custom_highlights = {

          CursorLineNr = { fg = light_pink },

          ['@variable'] = { fg = lighter_pink },
          ['@property'] = { fg = lighter_pink },
          ['@field'] = { fg = lighter_pink },
          ['@type.definition'] = { fg = lighter_pink },
          ['@constant'] = { fg = strong_purple },

          ['@function'] = { fg = light_pink },
          ['@function.builtin'] = { fg = light_pink },
          ['@function.call'] = { fg = light_pink },
          ['@keyword.operator'] = { fg = light_pink },

          ['@parameter'] = { fg = strong_orange },
          ['@variable.parameter'] = { fg = strong_orange },
          ['@keyword.return'] = { fg = vibrant_pink },

          ['@keyword.type'] = { fg = light_purple },
          ['@type'] = { fg = light_red },
          ['@type.builtin'] = { fg = light_red },
          ['@type.builtin.c'] = { fg = light_red },
          ['@keyword'] = { fg = light_red },
          ['@keyword.function'] = { fg = light_red },

          ['@keyword.import'] = { fg = vibrant_red },
          ['@keyword.directive.define.c'] = { fg = vibrant_red },

          ['@keyword.repeat'] = { fg = light_purple },
          ['@keyword.conditional'] = { fg = light_purple },

          ['@string'] = { fg = lighter_red },
          ['@character'] = { fg = lighter_red },

          ['@comment'] = { fg = grey },
          ['@punctuation.bracket'] = { fg = grey },

          ['@operator'] = { fg = white },

          ['@boolean'] = { fg = light_yellow },
          ['@number'] = { fg = light_yellow },
        },
      }
      vim.cmd.colorscheme 'catppuccin'
    end,
  },

  {
    'mechatroner/rainbow_csv',
    ft = { 'csv', 'tsv', 'csv.*' },
  },
}
