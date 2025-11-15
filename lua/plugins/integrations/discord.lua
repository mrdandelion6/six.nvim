return {
  'andweeb/presence.nvim',
  config = function()
    local dev_icons = 'https://raw.githubusercontent.com/mrdandelion6/assets/main/dev-icons/'
    require('presence').setup {
      auto_update = true,
      neovim_image_text = 'check out my config... https://github.com/mrdandelion6/six.nvim',
      main_image = 'neovim',
      file_assets = {
        cu = { 'CUDA', dev_icons .. 'nvidia.png' },
        cuh = { 'CUDA Header', dev_icons .. 'nvidia.png' },
        hip = { 'HIP', dev_icons .. 'amd.png' },
      },
    }
  end,
}
