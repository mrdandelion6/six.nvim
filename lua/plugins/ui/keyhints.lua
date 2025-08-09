return { -- useful plugin to show you pending keybinds.
  -- NOTE: have it in plugins/init.lua so it loads before other plugins, making it easier to document keybinds
  'folke/which-key.nvim',
  event = 'VimEnter',
  -- TODO: currently when remapping i to right movement, which key makes u need to press i twice in operator mode. eg) dii instead of di. not sure why
  opts = {
    icons = {
      -- set icon mappings to true if you have a Nerd Font
      mappings = vim.g.have_nerd_font,
      -- if you are using a nerd font: set icons.keys to an empty table which will use the
      -- default which-key.nvim defined Nerd Font icons, otherwise define a string table
      keys = vim.g.have_nerd_font and {} or {
        Up = '<Up> ',
        Down = '<Down> ',
        Left = '<Left> ',
        Right = '<Right> ',
        C = '<C-…> ',
        M = '<M-…> ',
        D = '<D-…> ',
        S = '<S-…> ',
        CR = '<CR> ',
        Esc = '<Esc> ',
        ScrollWheelDown = '<ScrollWheelDown> ',
        ScrollWheelUp = '<ScrollWheelUp> ',
        NL = '<NL> ',
        BS = '<BS> ',
        Space = '<Space> ',
        Tab = '<Tab> ',
        F1 = '<F1>',
        F2 = '<F2>',
        F3 = '<F3>',
        F4 = '<F4>',
        F5 = '<F5>',
        F6 = '<F6>',
        F7 = '<F7>',
        F8 = '<F8>',
        F9 = '<F9>',
        F10 = '<F10>',
        F11 = '<F11>',
        F12 = '<F12>',
      },
    },

    -- document existing key chains
    spec = {
      { '<leader>c', group = '[C]ode',          mode = { 'n', 'x' } },
      { '<leader>d', group = '[D]iagnose' },
      { '<leader>r', group = '[R]ename' },
      { '<leader>f', group = '[F]ind' },
      { '<leader>a', group = '[A]nother Cursor' },
      { '<leader>s', group = '[S]ession' },
      { '<leader>w', group = '[W]orkspace' },
      { '<leader>t', group = '[T]oggle' },
      { '<leader>m', group = '[M]essage',       mode = { 'n' } },
    },
  },
}
