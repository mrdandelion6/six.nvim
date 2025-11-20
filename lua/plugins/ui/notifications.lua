return {
  -- useful status updates for LSP.
  -- `opts = {}` is the same as calling `require('fidget').setup({})`
  'j-hui/fidget.nvim',
  config = function()
    local platform = require 'core.platform'
    -- border color
    local colors = require 'core.colors'
    vim.api.nvim_set_hl(0, 'FidgetBorder', { fg = colors.lighter_pink, bg = 'NONE' })

    local fidget_opts = {
      notification = {
        window = {
          normal_hl = '',
          winblend = 0,
          border = 'rounded',
          relative = 'win',
        },
        view = {
          stack_upwards = true,
          icon_separator = ' ',
          group_separator = '---',
          group_separator_hl = 'Comment',
        },
      },
    }

    -- TODO: this breaks on windows for some reason. figure out how to
    -- have pink border in windows
    if not platform.is_windows() then
      fidget_opts.notification.window.border_hl = 'FidgetBorder'
    end
    require('fidget').setup(fidget_opts)
  end,
}
