return {
  'mg979/vim-visual-multi', -- Allows for multi selection in buffer.
  branch = 'master',
  lazy = false,
  init = function()
    vim.g.VM_default_mappings = 0
    vim.g.VM_mouse_mappings = 0

    -- we may have existing mappings from core/keymaps.lua
    local existing_maps = vim.g.VM_maps or {}
    existing_maps['Select All'] = '<Leader>aa'
    existing_maps['Visual All'] = '<Leader>aa'
    existing_maps['Visual Cursors'] = '<Leader>ad'
    existing_maps['Skip Region'] = 'b'
    vim.g.VM_maps = existing_maps
  end,
}
