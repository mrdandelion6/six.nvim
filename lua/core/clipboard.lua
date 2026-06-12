-- sync clipboard between os and neovim.
-- schedule the setting after `uienter` because it can increase startup-time.
vim.schedule(function()
  vim.opt.clipboard = 'unnamedplus'

  -- osc 52 clipboard — works over ssh with no extra tools
  if vim.env.SSH_TTY ~= nil or vim.env.SSH_CONNECTION ~= nil then
    vim.g.clipboard = {
      name = 'OSC 52',
      copy = {
        ['+'] = require('vim.ui.clipboard.osc52').copy '+',
        ['*'] = require('vim.ui.clipboard.osc52').copy '*',
      },
      paste = {
        ['+'] = require('vim.ui.clipboard.osc52').paste '+',
        ['*'] = require('vim.ui.clipboard.osc52').paste '*',
      },
    }
  end
end)
