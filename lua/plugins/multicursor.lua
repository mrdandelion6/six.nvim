return {
  'mg979/vim-visual-multi', -- Allows for multi selection in buffer.
  branch = 'master',
  lazy = false,
  init = function()
    vim.g.VM_default_mappings = 1
    vim.g.VM_mouse_mappings = 1
    vim.g.VM_maps = {
      ['Select All'] = '<Leader>aa',
      ['Visual All'] = '<Leader>aa',
      ['Visual Cursors'] = '<Leader>ad',
      ['Skip Region'] = 'b',
    }
  end,
}
