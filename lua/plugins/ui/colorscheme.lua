local colors = require 'core.colors'

return {
  {
    'catppuccin/nvim',
    name = 'catppuccin',
    priority = 1000,
    init = function()
      -- pallete:

      require('catppuccin').setup {
        transparent_background = true,
        float = {
          transparent = true,
          solid = false,
        },
        -- you can choose flavors:
        -- 'mocha' (dark), 'macchiato', 'frappe', 'latte' (light)
        flavour = 'mocha',
        custom_highlights = {

          CursorLineNr = { fg = colors.light_pink },
          ['@variable'] = { fg = colors.lightest_pink },
          ['@variable.builtin'] = { fg = colors.light_pink },
          ['@property'] = { fg = colors.lightest_pink },
          ['@field'] = { fg = colors.lightest_pink },
          ['@type.definition'] = { fg = colors.lightest_pink },
          ['@constant'] = { fg = colors.strong_purple },

          Function = { fg = colors.light_pink },
          ['@function'] = { fg = colors.light_pink },
          ['@function.builtin'] = { fg = colors.light_pink },
          ['@function.call'] = { fg = colors.light_pink },
          ['@keyword.operator'] = { fg = colors.light_pink },
          ['@constructor'] = { fg = colors.light_pink },

          ['@parameter'] = { fg = colors.strong_orange },
          ['@variable.parameter'] = { fg = colors.strong_orange },
          ['@keyword.return'] = { fg = colors.vibrant_pink },

          Type = { fg = colors.light_red },
          ['@keyword.type'] = { fg = colors.vibrant_red },
          ['@type'] = { fg = colors.light_red },
          ['@type.builtin'] = { fg = colors.light_red },
          ['@type.builtin.c'] = { fg = colors.light_red },
          -- cpp
          ['@type.builtin.cpp'] = { fg = colors.light_red },

          -- TODO: figure out how to have different priority for class definition, declaration, and type
          -- ['@lsp.typemod.class.declaration.cpp'] = { fg = colors.light_pink },
          -- ['@lsp.typemod.class.definition.cpp'] = { fg = colors.light_pink },
          -- ['@lsp.typemod.class.globalScope.cpp'] = { fg = colors.light_pink },

          -- cuda
          ['@lsp.type.enumMember.cuda'] = { fg = colors.light_yellow },

          Keyword = { fg = colors.strong_purple },
          ['@keyword'] = { fg = colors.strong_purple },
          ['@keyword.function'] = { fg = colors.strong_purple },

          ['@keyword.import'] = { fg = colors.danger_red },
          ['@keyword.import.cpp'] = { fg = colors.danger_red },
          ['@keyword.directive.define.c'] = { fg = colors.danger_red },

          ['@keyword.repeat'] = { fg = colors.light_purple },
          ['@keyword.conditional'] = { fg = colors.light_purple },

          ['@string'] = { fg = colors.lighter_red },
          ['@character'] = { fg = colors.lighter_red },

          ['@comment'] = { fg = colors.grey },
          ['@punctuation.bracket'] = { fg = colors.grey },

          ['@operator'] = { fg = colors.white },

          ['@boolean'] = { fg = colors.light_yellow },
          ['@number'] = { fg = colors.light_yellow },

          ['@module'] = { fg = colors.light_blue },
        },
      }
      vim.cmd.colorscheme 'catppuccin'
    end,
  },
  {
    'mechatroner/rainbow_csv',
    event = 'BufReadPre',
    lazy = false,
    ft = { 'csv', 'tsv' },
  },
  {
    -- spawn color wheel for rgba text. useful for testing different hex codes
    -- and selecting colors directly inside neovim.
    'uga-rosa/ccc.nvim',
    lazy = false, -- make sure it loads right away
    config = function()
      require('ccc').setup()
      vim.api.nvim_set_hl(0, 'CccFloatBorder', { fg = colors.lighter_pink, bg = 'NONE' })
      vim.keymap.set('n', '<leader>cw', '<cmd>CccPick<CR>', { desc = '[C]olor [W]heel' })
    end,
  },
}
