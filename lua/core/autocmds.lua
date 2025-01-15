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

function Get_git_root()
  -- get the current buffer's file path
  local current_file = vim.fn.expand '%:p'
  if current_file == '' then
    -- print("1: returning '' - " .. vim.api.nvim_get_current_buf())
    return ''
  end

  -- get the directory of the current file
  local current_dir = vim.fn.fnamemodify(current_file, ':h')

  -- use git rev-parse with the current file's directory
  local cmd = string.format('git -C %s rev-parse --show-toplevel', vim.fn.shellescape(current_dir))
  local git_root = vim.fn.system(cmd)

  if vim.v.shell_error ~= 0 then
    return ''
  end

  -- clean up the output
  git_root = git_root:gsub('\n', '')

  if git_root ~= '' then
    return vim.fn.fnamemodify(git_root, ':t')
  end
  return ''
end

vim.api.nvim_create_user_command('GitRootTest', function()
  local result = Get_git_root()
end, {})
