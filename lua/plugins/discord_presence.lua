return {
  'andweeb/presence.nvim',
  config = function()
    require('presence').setup {
      auto_update = true,
      neovim_image_text = 'check out my config... github.com/mrdandelion6/six.nvim',
      main_image = 'neovim',
    }
  end,
}
