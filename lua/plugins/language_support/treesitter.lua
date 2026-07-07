return {
  'nvim-treesitter/nvim-treesitter',
  branch = 'master',

  build = ':TSUpdate',
  dependencies = {
    {
      'nvim-treesitter/nvim-treesitter-textobjects',
      branch = 'master',
    },
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
      },
      indent = { enable = true },

      textobjects = {
        select = {
          enable = true,
          lookahead = true,
          keymaps = {
            ['af'] = { query = '@function.outer', desc = '[A]round [F]unction' },
            ['ac'] = { query = '@code_cell.outer', desc = '[A]round [C]ode cell' },
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

    -- NOTE: for changing keymap layouts we have the below
    local select = require 'nvim-treesitter.textobjects.select'

    local function set_layout_textobjects()
      if vim.g.local_settings == nil then
        print 'ERROR (treesitter.lua): vim.g.local_settings is nil'
        return
      end

      local layout = vim.g.local_settings.keyboard_layout
      if layout == nil then
        print 'ERROR (treesitter.lua): vim.g.local_settings.keyboard_layout is nil'
        return
      end

      local new_prefix
      local old_prefix

      if layout == 'colemak' then
        new_prefix = 'l'
        old_prefix = 'i'
      elseif layout == 'qwerty' then
        new_prefix = 'i'
        old_prefix = 'l'
      else
        return
      end

      pcall(vim.keymap.del, { 'x', 'o' }, old_prefix .. 'f')
      pcall(vim.keymap.del, { 'x', 'o' }, old_prefix .. 'c')

      vim.keymap.set({ 'x', 'o' }, new_prefix .. 'f', function()
        select.select_textobject('@function.inner', 'textobjects')
      end, { desc = 'Inside Function' })

      vim.keymap.set({ 'x', 'o' }, new_prefix .. 'c', function()
        select.select_textobject('@code_cell.inner', 'textobjects')
      end, { desc = 'Inside Code cell' })
    end

    local group = vim.api.nvim_create_augroup('treesitter_keyboard_layout', { clear = true })

    vim.api.nvim_create_autocmd('User', {
      group = group,
      pattern = 'KeyboardLayoutChanged',
      callback = set_layout_textobjects,
    })

    set_layout_textobjects()
  end,
}
