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

function M.is_markdown_mode()
  return vim.g.started_by_firenvim or vim.env['MD_MODE'] == '1'
end

-- copy the most recent message
function M.Copy_recent_message()
  local message = vim.fn.trim(vim.fn.execute '1messages')
  vim.fn.setreg('*', message) -- Copy to selection register
  vim.fn.setreg('+', message) -- Copy to system clipboard
  print('Message copied: ' .. message)
end

return M
