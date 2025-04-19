vim.opt.mouse = 'a'

-- line numbers
vim.opt.number = true
vim.opt.relativenumber = true

-- don't show the mode, since it's already in the status line
vim.opt.showmode = false

-- sync clipboard between os and neovim.
-- schedule the setting after `uienter` because it can increase startup-time.
vim.schedule(function()
  vim.opt.clipboard = 'unnamedplus'
end)

-- tab
vim.opt.tabstop = 2      -- number of spaces that a <tab> counts for
vim.opt.shiftwidth = 2   -- number of spaces to use for autoindent
vim.opt.expandtab = true -- use spaces instead of tabs
vim.opt.softtabstop = 2  -- number of spaces that a <tab> counts for while performing editing operations

-- text wrapping for buffers
vim.opt.breakindent = true

-- save undo history
vim.opt.undofile = true

-- case-insensitive searching unless \C or one or more capital letters in the search term
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- signcolumn is space for symbols left of line numbers like git changes
vim.opt.signcolumn = 'yes'

-- decrease update time
vim.opt.updatetime = 250

-- decrease mapped sequence wait time
-- displays which-key popup sooner
vim.opt.timeoutlen = 300

-- configure how new splits should be opened
vim.opt.splitright = true
vim.opt.splitbelow = true

-- how nvim will display whitespace characters in the editor
vim.opt.list = true
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }

-- preview substitutions live, as you type!
vim.opt.inccommand = 'split'

-- show which line your cursor is on
vim.opt.cursorline = true

-- minimal number of screen lines to keep above and below the cursor.
vim.opt.scrolloff = 999

-- split lines
vim.opt.laststatus = 3 -- use 3 for global status bar
vim.opt.fillchars = {
  horiz = '─',
  horizup = '─',
  horizdown = '─',
  vert = '│',
  vertleft = '│',
  vertright = '│',
  verthoriz = '┼',
}

-- python virtual environment for any deps
vim.g.python3_host_prog = vim.fn.expand '~/.envs/neovim/bin/python3'

local function verify_settings_format(settings)
  if not settings then
    print 'ERROR (core/optins.lua): settings is nil'
    return 1
  elseif not settings.layout then
    print 'ERROR (core/optins.lua): settings.layout is nil'
    return 1
  end
  return 0
end
-- load local settings globally
local settings_path = vim.fn.stdpath 'config' .. '/.localsettings.json'
if vim.fn.filereadable(settings_path) then
  local success, settings = pcall(function()
    return vim.fn.json_decode(vim.fn.readfile(settings_path, 'b'))
  end)
  if verify_settings_format(settings) == 0 then
    vim.g.local_settings = settings
  end
else
  print('ERROR: .localsettings.json not found at: ' .. settings_path)
end
