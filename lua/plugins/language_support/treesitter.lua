return {
  'nvim-treesitter/nvim-treesitter',
  build = ':TSUpdate',
  dependencies = {
    'nvim-treesitter/nvim-treesitter-textobjects',
    'nvim-treesitter/playground',
  },
  config = function()
    ---@diagnostic disable-next-line: missing-fields
    require('nvim-treesitter.configs').setup {
      ensure_installed = {
        'bash',
        'c',
        'diff',
        'html',
        'lua',
        'luadoc',
        'markdown',
        'markdown_inline',
        'query',
        'vim',
        'vimdoc',
        'python',
        'javascript',
        'json',
        'yaml',
      },
      auto_install = true,

      highlight = {
        enable = true,
        additional_vim_regex_highlighting = { 'ruby' },
      },

      indent = { enable = true, disable = { 'ruby' } },

      playground = {
        enable = true,
      },

      textobjects = {
        select = {
          enable = true,
          lookahead = true,
          keymaps = {
            ['af'] = { query = '@function.outer', desc = '[A]round [F]unction' },
            ['if'] = { query = '@function.inner', desc = '[I]nside [F]unction' },
            ['ac'] = { query = '@code_cell.inner', desc = '[A]round [C]ode cell' },
            ['ic'] = { query = '@code_cell.inner', desc = '[I]nside [C]ode cell' },
          },
        },
        move = {
          enable = true,
          set_jumps = true,
          goto_next_start = {
            [']f'] = { query = '@function.outer', desc = 'Next [F]unction start' },
            [']]'] = { query = '@code_cell.inner', desc = 'Next [C]ode cell start' },
          },
          goto_next_end = {
            [']F'] = { query = '@function.outer', desc = 'Next [F]unction end' },
            [']['] = { query = '@code_cell.inner', desc = 'Next [C]ode cell end' },
          },
          goto_previous_start = {
            ['[f'] = { query = '@function.outer', desc = 'Previous [F]unction start' },
            ['[['] = { query = '@code_cell.inner', desc = 'Previous [C]ode cell start' },
          },
          goto_previous_end = {
            ['[F'] = { query = '@function.outer', desc = 'Previous [F]unction end' },
            ['[]'] = { query = '@code_cell.inner', desc = 'Previous [C]ode cell end' },
          },
        },
      },
    }

    -- force load the textobjects module after setup
    local ts_repeat_move = require 'nvim-treesitter.textobjects.repeatable_move'
  end,
}
