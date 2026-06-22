-- sync clipboard between os and neovim.
-- schedule the setting after `uienter` because it can increase startup-time.
vim.schedule(function()
  vim.opt.clipboard = 'unnamedplus'

  -- osc 52 clipboard — works over ssh with no extra tools
  if vim.env.SSH_TTY ~= nil or vim.env.SSH_CONNECTION ~= nil then
    -- wezterm honors osc 52 copy (write) but not paste (read): the paste
    -- handler queries the terminal and blocks waiting for a reply that never
    -- comes. read from the unnamed register instead so paste never hangs.
    local function paste()
      return vim.split(vim.fn.getreg '"', '\n')
    end

    vim.g.clipboard = {
      name = 'OSC 52',
      copy = {
        ['+'] = require('vim.ui.clipboard.osc52').copy '+',
        ['*'] = require('vim.ui.clipboard.osc52').copy '*',
      },
      paste = {
        ['+'] = paste,
        ['*'] = paste,
      },
    }
  end
end)
