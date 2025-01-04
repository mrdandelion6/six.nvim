return { -- spawn color wheel for rgba text
  'uga-rosa/ccc.nvim',
  lazy = false, -- make sure it loads right away
  config = function()
    require('ccc').setup()
    vim.keymap.set('n', '<leader>cw', '<cmd>CccPick<CR>', { desc = '[C]olor [W]heel' })
  end,
}
