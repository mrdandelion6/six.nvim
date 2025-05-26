local M = {}
M.platform = nil

if vim.fn.has 'win32' == 1 or vim.fn.has 'win64' == 1 then
  M.platform = 'windows'
elseif vim.fn.has 'mac' == 1 or vim.fn.has 'macunix' == 1 then
  M.platform = 'mac'
elseif vim.fn.has 'unix' == 1 then
  M.platform = 'linux'
else
  print 'ERROR (platform.lua): platform not recognized'
end

-- helper function to handle errors and return results
local function execute_command(cmd)
  local result = vim.fn.system(cmd)
  local success = vim.v.shell_error == 0

  if not success then
    print('ERROR: ' .. result)
  end

  return success, result
end

-- helper function to escape paths for shell commands
local function escape_path(path)
  if M.platform == 'windows' then
    -- For PowerShell, escape single quotes and wrap in single quotes
    path = path:gsub("'", "''")
    return "'" .. path .. "'"
  else
    -- For Unix shells, use vim's shellescape
    return vim.fn.shellescape(path)
  end
end

-- Copy file(s) from src to dst
function M.cp(src, dst)
  -- Ensure paths are provided
  if not src or not dst then
    print 'ERROR: Source and destination paths are required'
    return false
  end

  local cmd = ''

  if M.platform == 'windows' then
    -- Check if PowerShell is available
    local has_powershell = vim.fn.executable 'powershell' == 1 or vim.fn.executable 'pwsh' == 1
    local powershell_cmd = vim.fn.executable 'pwsh' == 1 and 'pwsh' or 'powershell'

    if has_powershell then
      -- Use PowerShell's Copy-Item
      src = escape_path(src)
      dst = escape_path(dst)
      cmd = powershell_cmd .. ' -NoProfile -Command "Copy-Item -Path ' .. src .. ' -Destination ' .. dst .. ' -Force -Recurse"'
    else
      -- Fallback to cmd's copy
      cmd = 'copy /Y "' .. src:gsub('/', '\\') .. '" "' .. dst:gsub('/', '\\') .. '"'
    end
  else
    -- Unix (Linux/macOS) systems use cp
    src = escape_path(src)
    dst = escape_path(dst)
    cmd = 'cp -rf ' .. src .. ' ' .. dst
  end

  return execute_command(cmd)
end

-- Move file(s) from src to dst
function M.mv(src, dst)
  -- Ensure paths are provided
  if not src or not dst then
    print 'ERROR: Source and destination paths are required'
    return false
  end

  local cmd = ''

  if M.platform == 'windows' then
    -- Check if PowerShell is available
    local has_powershell = vim.fn.executable 'powershell' == 1 or vim.fn.executable 'pwsh' == 1
    local powershell_cmd = vim.fn.executable 'pwsh' == 1 and 'pwsh' or 'powershell'

    if has_powershell then
      -- Use PowerShell's Move-Item
      src = escape_path(src)
      dst = escape_path(dst)
      cmd = powershell_cmd .. ' -NoProfile -Command "Move-Item -Path ' .. src .. ' -Destination ' .. dst .. ' -Force"'
    else
      -- Fallback to cmd's move
      cmd = 'move /Y "' .. src:gsub('/', '\\') .. '" "' .. dst:gsub('/', '\\') .. '"'
    end
  else
    -- Unix (Linux/macOS) systems use mv
    src = escape_path(src)
    dst = escape_path(dst)
    cmd = 'mv -f ' .. src .. ' ' .. dst
  end

  return execute_command(cmd)
end

function M.set_shell()
  if M.platform == 'windows' then
    vim.opt.shell = 'powershell'
    vim.opt.shellcmdflag = '-command'
    vim.opt.shellquote = '"'
    vim.opt.shellxquote = ''
  end
  -- for linux default is already /bin/bash
end

function M.startup()
  M.set_shell()
end

return M
