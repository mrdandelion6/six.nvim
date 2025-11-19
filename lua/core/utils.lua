local M = {}

function M.union_tables(...)
  local result = {}
  for _, tbl in ipairs { ... } do
    vim.list_extend(result, tbl)
  end
  return result
end

function M.is_markdown_mode()
  return vim.g.started_by_firenvim or vim.env['MD_MODE'] == '1'
end

-- copy the most recent message
function M.copy_recent_message()
  local message = vim.fn.trim(vim.fn.execute '1messages')
  vim.fn.setreg('*', message) -- copy to selection register
  vim.fn.setreg('+', message) -- copy to system clipboard
  print('Message copied: ' .. message)
end

function M.get_git_root(return_full_path)
  -- only run this function on regular file types
  if vim.bo.buftype ~= '' then
    return ''
  end

  local current_file = vim.fn.expand '%:p'
  if current_file == '' then
    -- this is for when we are viewing directory
    return ''
  end

  -- get the directory of the current file
  local current_dir = vim.fn.fnamemodify(current_file, ':h')
  if not current_dir:match '/$' then
    current_dir = current_dir .. '/'
  end
  current_dir = current_dir:gsub('\\', '/')

  -- check our cache first. this is especially good for windows, which takes
  -- longer for git rev-parse.
  local cache = vim.g.git_root_cache or {}
  local git_root = nil

  for key, value in pairs(cache) do
    if current_dir:sub(1, #key) == key then
      -- value in cache is the dir name , but we need to check what to return
      if return_full_path then
        return key:gsub('/$', '') -- remove trailing slash for full path
      else
        return value
      end
    end
  end

  -- use git rev-parse with the current file's directory

  local rev_parse_result = vim.system({ 'git', '-C', current_dir, 'rev-parse', '--show-toplevel' }):wait()

  -- git rev-parse found no git root
  local no_git_root_found = (not rev_parse_result)
  or (rev_parse_result.code ~= 0)
  or (not rev_parse_result.stdout)
  or (rev_parse_result.stdout == '')

  if no_git_root_found then
    -- cache that this path has no git root
    cache[current_dir] = ''
    vim.g.git_root_cache = cache
    return ''
  end

  git_root = rev_parse_result.stdout

  -- clean up the output
  git_root = git_root:gsub('\\', '/')
  git_root = git_root:gsub('\n', '')
  local git_root_dir_name = vim.fn.fnamemodify(git_root, ':t')
  if not git_root:match '/$' then
    git_root = git_root .. '/'
  end

  -- cache it (cache key is full path, value is dir name)
  cache[git_root] = git_root_dir_name
  vim.g.git_root_cache = cache

  -- return based on parameter
  if return_full_path then
    return git_root:gsub('/$', '') -- remove trailing slash for consistency
  else
    return git_root_dir_name
  end
end

return M
