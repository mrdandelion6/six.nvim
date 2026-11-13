local M = {}

function M.union_tables(...)
  local result = {}
  for _, tbl in ipairs { ... } do
    vim.list_extend(result, tbl)
  end
  return result
end

-- MEMORY USAGE:
-- combined resident memory (RSS) of nvim and every process under it (lsp
-- servers, fzf, fd, terminals, ...). a background `ps` call refreshes the
-- value every 2s so callers (e.g. the statusline) never block. shared memory
-- gets counted once per process, so this slightly overestimates. not on windows.
local mem_usage = ''
local mem_usage_kb = nil
local mem_timer = nil

-- kb -> '87M' under 1000M, otherwise '2.3G' ('2G' when the decimal is 0)
function M.format_mem(kb)
  local mb = kb / 1024
  if mb < 1000 then
    return string.format('%dM', math.floor(mb + 0.5))
  end
  return (string.format('%.1fG', mb / 1024):gsub('%.0G$', 'G'))
end

-- parse `ps -eo pid=,ppid=,rss=` output and return {pid = rss_kb} for `root`
-- and every process under it, plus a {pid = ppid} map of every process
local function proc_tree_rss(ps_stdout, root)
  local children, rss, parent = {}, {}, {}
  for pid, ppid, kb in ps_stdout:gmatch '(%d+)%s+(%d+)%s+(%d+)' do
    pid, ppid = tonumber(pid), tonumber(ppid)
    rss[pid] = tonumber(kb)
    parent[pid] = ppid
    children[ppid] = children[ppid] or {}
    table.insert(children[ppid], pid)
  end
  local tree, stack = {}, { root }
  while #stack > 0 do
    local pid = table.remove(stack)
    tree[pid] = rss[pid] or 0
    for _, child in ipairs(children[pid] or {}) do
      table.insert(stack, child)
    end
  end
  return tree, parent
end

-- node renames its main thread (and so its process name) to 'node-MainThread'
local function is_node(comm, cmd)
  local exe = (cmd:match '^(%S+)' or ''):match '[^/]+$'
  return comm == 'node-MainThread' or comm == 'node' or exe == 'node'
end

-- name of the script a node process runs, e.g.
--   'node /x/bin/typescript-language-server --stdio' -> 'typescript-language-server'
--   'node /x/lib/tsserver.js --server'                -> 'tsserver'
--   'node /x/npx-cli.js prettier'                     -> 'prettier'
local function node_script_name(cmd)
  local tokens = vim.split(cmd, '%s+', { trimempty = true })
  local i = 2 -- tokens[1] is the node executable
  while tokens[i] and tokens[i]:sub(1, 1) == '-' do
    i = i + 1 -- skip node flags like --max-old-space-size=4096
  end
  local function base(tok)
    return (tok:match '[^/]+$' or tok):gsub('%.[mc]?js$', '')
  end
  local name = tokens[i] and base(tokens[i])
  if name == 'npx' or name == 'npx-cli' then
    -- npx runs another tool, name it after that tool instead
    i = i + 1
    while tokens[i] and tokens[i]:sub(1, 1) == '-' do
      i = i + 1
    end
    name = tokens[i] and base(tokens[i]) or name
  end
  return name or 'node'
end

-- every process in nvim's tree (nvim itself included) as a list of
-- { pid, rss (kb), name, args, is_nvim }. runs ps synchronously, meant for
-- one-off use (e.g. the <leader>fm picker), not for the statusline
function M.mem_processes()
  if require('core.platform').is_windows() then
    return {} -- no ps on windows; <leader>fm shows a 'not available' notice
  end
  local nvim_pid = vim.fn.getpid()
  local out = vim.system({ 'ps', '-eo', 'pid=,ppid=,rss=' }, { text = true }):wait()
  if out.code ~= 0 or not out.stdout then
    return {}
  end
  local tree, parent = proc_tree_rss(out.stdout, nvim_pid)
  local pids = vim.tbl_keys(tree)

  -- names and full command lines. comm/args go last since they can contain spaces
  local function ps_field(field)
    local res = {}
    local o = vim
      .system({ 'ps', '-o', 'pid=,' .. field .. '=', '-p', table.concat(pids, ',') }, { text = true })
      :wait()
    for line in (o.stdout or ''):gmatch '[^\n]+' do
      local pid, val = line:match '^%s*(%d+)%s+(.*)$'
      if pid then
        res[tonumber(pid)] = val
      end
    end
    return res
  end
  local comms, args = ps_field 'comm', ps_field 'args'

  local function pid_is_node(pid)
    return comms[pid] ~= nil and is_node(comms[pid], args[pid] or '')
  end

  local procs = {}
  for pid, rss in pairs(tree) do
    if comms[pid] then -- skip processes that exited in the meantime
      local name, cmd = comms[pid], args[pid] or ''
      if pid_is_node(pid) then
        -- group node processes under the topmost node process they belong to
        -- (e.g. tsserver.js under typescript-language-server), named after
        -- its script. stops at the first non-node parent (e.g. nvim), so
        -- separate node tools stay separate groups
        local top = pid
        while parent[top] and tree[parent[top]] and pid_is_node(parent[top]) do
          top = parent[top]
        end
        name = node_script_name(args[top] or '')
      else
        -- linux truncates comm to 15 chars (e.g. 'lua-language-se'), use the
        -- executable's full name from the command line in that case
        local exe = (cmd:match '^(%S+)' or ''):match '[^/]+$'
        if #name >= 15 and exe and exe:sub(1, #name) == name then
          name = exe
        end
      end
      table.insert(
        procs,
        { pid = pid, rss = rss, name = name, args = cmd, is_nvim = pid == nvim_pid }
      )
    end
  end
  return procs
end

-- start refreshing the memory usage in the background. safe to call more than
-- once, only one timer is ever created
function M.start_mem_usage()
  if mem_timer or require('core.platform').is_windows() then
    return
  end
  local nvim_pid = vim.fn.getpid()
  local ps_running = false

  local function update()
    if ps_running then
      return
    end
    ps_running = true
    vim.system({ 'ps', '-eo', 'pid=,ppid=,rss=' }, { text = true }, function(out)
      ps_running = false
      if out.code ~= 0 or not out.stdout then
        return
      end
      -- add up the rss of nvim and every process under it
      local total = 0
      for _, kb in pairs(proc_tree_rss(out.stdout, nvim_pid)) do
        total = total + kb
      end
      mem_usage_kb = total
      mem_usage = M.format_mem(total)
    end)
  end

  mem_timer = vim.uv.new_timer()
  mem_timer:start(0, 2000, update)
  vim.api.nvim_create_autocmd('VimLeavePre', {
    callback = function()
      mem_timer:stop()
      mem_timer:close()
    end,
  })
end

-- latest memory usage string, '' until the first reading (or on windows)
function M.mem_usage()
  return mem_usage
end

-- latest memory usage in kb, nil until the first reading (or on windows)
function M.mem_usage_kb()
  return mem_usage_kb
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

-- the directory the current buffer "lives in", resolved the same way lualine's
-- branch component does it, so the repo title and branch always agree:
--   file -> its dir, terminal -> dir it was started in, oil -> listed dir,
--   fugitive -> repo work tree, anything else (empty, help, ...) -> cwd
local function buffer_dir()
  local name = vim.api.nvim_buf_get_name(0)
  if package.loaded.oil then
    local ok, dir = pcall(require('oil').get_current_dir)
    if ok and dir and dir ~= '' then
      return dir
    end
  end
  local term_dir = name:match '^term://(.-)//'
  if term_dir then
    return vim.fn.expand(term_dir)
  end
  if name:match '^fugitive://' and vim.fn.exists '*FugitiveWorkTree' == 1 then
    local tree = vim.fn.FugitiveWorkTree()
    if tree ~= '' then
      return tree
    end
  end
  if vim.bo.buftype == '' and name ~= '' then
    return vim.fn.fnamemodify(name, ':p:h')
  end
  return vim.fn.getcwd()
end

-- git repo containing the current buffer (see buffer_dir). returns the repo's
-- dir name, or its full path when return_full_path is set. '' if not in a repo
function M.get_git_root(return_full_path)
  -- vim.fs.root walks up looking for a .git dir/file (same check lualine does),
  -- just a few stat calls, so no cache or `git rev-parse` process needed
  local ok, root = pcall(vim.fs.root, buffer_dir(), '.git')
  if not ok or not root then
    return ''
  end
  root = root:gsub('\\', '/')
  if return_full_path then
    return root
  end
  return vim.fn.fnamemodify(root, ':t')
end

return M
