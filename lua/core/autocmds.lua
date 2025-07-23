--  since we use ctrl+<hjkl> to switch between windows
--  need to first free <C-l> from netrw. we delete it.
--  netrw (built in tool of vim) is what we are currently used for file tree.
--  one of netrw's commands is <C-l> which we need for moving to right split.

vim.api.nvim_create_autocmd('FileType', {
  pattern = 'netrw',
  callback = function()
    pcall(function()
      vim.keymap.del('n', '<C-l>', { buffer = true })
    end)
  end,
})

-- highlight when yanking (copying) text
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})

local function get_git_root()
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

  -- check our cache first. this is especialy good for windows , which takes
  -- longer for git rev-parse.
  local cache = vim.g.git_root_cache or {}
  local git_root = nil

  for key, value in pairs(cache) do
    if current_dir:sub(1, #key) == key then
      return value
    end
  end

  -- use git rev-parse with the current file's directory
  local cmd = string.format('git -C %s rev-parse --show-toplevel', vim.fn.shellescape(current_dir))
  git_root = vim.fn.system(cmd)

  if vim.v.shell_error ~= 0 then
    -- no match found , cache
    cache[current_dir] = ''
    vim.g.git_root_cache = cache
    return ''
  end

  -- clean up the output
  git_root = git_root:gsub('\\', '/')
  git_root = git_root:gsub('\n', '')
  local git_root_dir_name = vim.fn.fnamemodify(git_root, ':t')
  if not git_root:match '/$' then
    git_root = git_root .. '/'
  end

  -- cache it
  cache[git_root] = git_root_dir_name
  vim.g.git_root_cache = cache

  return git_root_dir_name
end

vim.api.nvim_create_autocmd({ 'BufEnter' }, {
  callback = function()
    vim.g.git_root = get_git_root()
  end,
})

vim.api.nvim_create_user_command('DisableFormatting', function()
  local bufnr = vim.api.nvim_get_current_buf()

  -- disable lsp formatting capabilities for this buffer only
  vim.b.disable_formatting = true

  -- get all attached clients for this buffer
  local clients = vim.lsp.get_clients { buffer = bufnr }
  for _, client in ipairs(clients) do
    client.server_capabilities.documentFormattingProvider = false
    client.server_capabilities.documentRangeFormattingProvider = false
  end

  print 'Formatting disabled for current buffer'
end, {})

-- always center
local original_scrolloff = vim.o.scrolloff
function Center_cursor()
  if vim.b.scrolloff_processing then
    return
  end
  vim.b.scrolloff_processing = true

  -- get cursor and window height
  vim.o.scrolloff = 0
  local win_h = vim.api.nvim_win_get_height(0)
  local half_h = math.floor(win_h / 2)
  local cursor_h = vim.fn.line '.' - vim.fn.line 'w0' + 1

  -- get offset
  local offset = cursor_h - half_h

  -- apply offset
  local win_view = vim.fn.winsaveview()
  win_view.skipcol = 0
  win_view.topline = win_view.topline + offset
  vim.fn.winrestview(win_view)

  vim.b.scrolloff_processing = false
end

vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI', 'BufEnter' }, {
  group = vim.api.nvim_create_augroup('ScrollOffEOF', {}),
  callback = Center_cursor,
})

-- important for things like undo command.
vim.api.nvim_create_autocmd('TextChanged', {
  callback = Center_cursor,
})
