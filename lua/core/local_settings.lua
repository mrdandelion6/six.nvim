local platform = require 'core.platform'

local function verify_settings_format(settings)
  if not settings then
    print 'ERROR (core/local_settings.lua): settings is nil. TIP: run cp .localsettings_template.json .localsettings.json.'
    return 1
  elseif not settings.venv_path then
    print 'ERROR (core/local_settings.lua): settings.env_path is nil. TIP: see .localsettings_template.json for example.'
    return 1
  end
  return 0
end

-- read .localsettings.json
local settings_path = vim.fn.stdpath 'config' .. '/.localsettings.json'
local exists = vim.fn.filereadable(settings_path)
if exists == 0 then
  print('WARNING (local_settings.lua): .localsettings.json not found at: ' ..
    settings_path .. '. generating file from .localsettings_template.json')
  local template_path = vim.fn.stdpath 'config' .. '/.localsettings_template.json'
  platform.cp(template_path, settings_path)
  local copy_success = vim.v.shell_error == 0
  if not copy_success then
    print 'ERROR (local_settings.lua): failed to copy template file'
  end
end

-- load local settings globally
local success, settings = pcall(function()
  return vim.fn.json_decode(vim.fn.readfile(settings_path, 'b'))
end)

if not success then
  print('ERROR (local_settings.lua): issue parsing json file: ' .. settings)
elseif verify_settings_format(settings) == 0 then
  settings.keyboard_layout_path = vim.fn.expand(settings.keyboard_layout_path)
  settings.keyboard_layout = 'qwerty'
  vim.g.local_settings = settings
end

-- read keyboard layout from separate file
if vim.g.local_settings then
  local success, layout = pcall(function()
    local path = vim.g.local_settings.keyboard_layout_path
    return vim.trim(vim.fn.readfile(path)[1])
  end)

  if not success then
    print('ERROR (local_settings.lua): issue parsing layout file: ' .. layout)
  else
    local settings = vim.g.local_settings
    settings.keyboard_layout = layout
    vim.g.local_settings = settings
  end
end

-- python virtual environment for any deps
if vim.g.local_settings then
  vim.g.python3_host_prog = vim.g.local_settings.venv_path .. 'neovim/bin/python'
end
