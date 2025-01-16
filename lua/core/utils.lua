local M = {}

function M.deepcopy(orig)
  local orig_type = type(orig)
  local copy
  if orig_type == 'table' then
    copy = {}
    for orig_key, orig_value in next, orig, nil do
      copy[M.deepcopy(orig_key)] = M.deepcopy(orig_value)
    end
    setmetatable(copy, M.deepcopy(getmetatable(orig)))
  else
    copy = orig
  end
  return copy
end

function M.IsLinux()
  return vim.fn.has 'unix' == 1 and vim.fn.has 'mac' == 0
end

function M.IsWSL()
  return M.IsLinux() and vim.fn.system('uname -r'):lower():match 'microsoft' ~= nil
end

function M.IsMac()
  return vim.fn.has 'mac' == 1
end

function M.IsWindows()
  return vim.fn.has 'win32' == 1
end

function M.MarkdownMode()
  return vim.g.started_by_firenvim or vim.env['MD_MODE'] == '1'
end

return M
