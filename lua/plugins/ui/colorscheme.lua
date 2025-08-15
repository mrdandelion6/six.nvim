-- colors
local white = '#d5dae1'
local grey = '#c4bdd2'

local light_yellow = '#f5c287'

local light_orange = '#f5b579'
local strong_orange = '#eaa658'

local lighter_red = '#e89bb6'
local light_red = '#de80a1'
local vibrant_red = '#ff5f83'
local danger_red = '#e43b53'

local test = '#ff86b4'
local lighter_pink = '#ffddff'
local light_pink = '#ffb0ff'
local strong_pink = '#fe89f3'
local vibrant_pink = '#ff6dba'

local light_purple = '#a6b2fc'
local strong_purple = '#a68cf0'

local light_blue = '#52d7ff'
local strong_blue = '#89b4fa'
local turqouise = '#9effe6'

return {
  {
    'catppuccin/nvim',
    name = 'catppuccin',
    priority = 1000,
    init = function()
      -- pallete:

      require('catppuccin').setup {
        transparent_background = true,
        -- you can choose flavors:
        -- 'mocha' (dark), 'macchiato', 'frappe', 'latte' (light)
        flavour = 'mocha',
        custom_highlights = {

          CursorLineNr = { fg = light_pink },
          ['@variable'] = { fg = lighter_pink },
          ['@variable.builtin'] = { fg = light_pink },
          ['@property'] = { fg = lighter_pink },
          ['@field'] = { fg = lighter_pink },
          ['@type.definition'] = { fg = lighter_pink },
          ['@constant'] = { fg = strong_purple },

          Function = { fg = light_pink },
          ['@function'] = { fg = light_pink },
          ['@function.builtin'] = { fg = light_pink },
          ['@function.call'] = { fg = light_pink },
          ['@keyword.operator'] = { fg = light_pink },

          ['@parameter'] = { fg = strong_orange },
          ['@variable.parameter'] = { fg = strong_orange },
          ['@keyword.return'] = { fg = vibrant_pink },

          Type = { fg = light_red },
          ['@keyword.type'] = { fg = vibrant_red },
          ['@type'] = { fg = light_red },
          ['@type.builtin'] = { fg = light_red },
          ['@type.builtin.c'] = { fg = light_red },
          -- cpp
          ['@type.builtin.cpp'] = { fg = light_red },
          -- TODO: figure out how to have different priority for class definition, declaration, and type
          -- ['@lsp.typemod.class.declaration.cpp'] = { fg = light_pink },
          -- ['@lsp.typemod.class.definition.cpp'] = { fg = light_pink },
          -- ['@lsp.typemod.class.globalScope.cpp'] = { fg = light_pink },

          Keyword = { fg = strong_purple },
          ['@keyword'] = { fg = strong_purple },
          ['@keyword.function'] = { fg = strong_purple },

          ['@keyword.import'] = { fg = danger_red },
          ['@keyword.directive.define.c'] = { fg = danger_red },

          ['@keyword.repeat'] = { fg = light_purple },
          ['@keyword.conditional'] = { fg = light_purple },

          ['@string'] = { fg = lighter_red },
          ['@character'] = { fg = lighter_red },

          ['@comment'] = { fg = grey },
          ['@punctuation.bracket'] = { fg = grey },

          ['@operator'] = { fg = white },

          ['@boolean'] = { fg = light_yellow },
          ['@number'] = { fg = light_yellow },

          ['@module'] = { fg = light_blue },
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
      vim.keymap.set('n', '<leader>cw', '<cmd>CccPick<CR>', { desc = '[C]olor [W]heel' })
    end,
  },
}
