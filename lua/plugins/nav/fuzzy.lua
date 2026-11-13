return {
  'ibhagwan/fzf-lua',
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  event = 'VimEnter',
  config = function()
    local fzf = require 'fzf-lua'
    local utils = require 'fzf-lua.utils'
    local actions = require 'fzf-lua.actions'
    local colors = require 'core.colors'

    local function hl_validate(hl)
      return not utils.is_hl_cleared(hl) and hl or nil
    end

    --[[
    **************************************************************************
                              FILE FINDER (fd)
    **************************************************************************
    --]]
    -- fd only lists paths (never reads contents) , so binaries are skipped by
    -- extension rather than by inspecting the file.

    -- directories to never descend into (matched by name at any depth)
    local excluded_dirs = {
      '.git',
      'lib',
      'node_modules',
      'target',
      'dist',
      'build',
      '.tex',
      '.cache',
      '.npm',
      '.cargo',
    }

    -- binary / non-text file extensions to hide from the picker. globs are
    -- case-sensitive, so both lower and upper case variants get excluded
    local excluded_exts = {
      -- compiled objects / libraries / executables
      'o',
      'obj',
      'so',
      'a',
      'lib',
      'dll',
      'dylib',
      'exe',
      'bin',
      'out',
      'class',
      'jar',
      'pyc',
      'pyo',
      'wasm',
      -- images
      'png',
      'jpg',
      'jpeg',
      'gif',
      'bmp',
      'webp',
      'ico',
      'tiff',
      'psd',
      -- documents
      'pdf',
      'doc',
      'docx',
      'xls',
      'xlsx',
      'ppt',
      'pptx',
      -- archives
      'zip',
      'tar',
      'gz',
      'tgz',
      'bz2',
      'xz',
      'zst',
      '7z',
      'rar',
      'iso',
      -- audio / video
      'mp3',
      'wav',
      'flac',
      'ogg',
      'mp4',
      'mkv',
      'mov',
      'avi',
      'webm',
      -- fonts
      'ttf',
      'otf',
      'woff',
      'woff2',
      -- databases
      'sqlite',
      'db',
      -- ml models / tensors
      'gguf',
      'safetensors',
      'pt',
      'pth',
      'ckpt',
      'onnx',
      'h5',
      'npy',
      'npz',
      -- disk / vm images
      'img',
      'qcow2',
      'vmdk',
      'vdi',
      'dmg',
    }

    -- opts.all_filesystems: cross into other mounts (used by :FuzzyAll)
    local function files_cmd(opts)
      opts = opts or {}
      local fd = vim.fn.executable 'fd' == 1 and 'fd' or 'fdfind' -- ubuntu names it fdfind
      local args = {
        fd,
        '--type f',
        -- no --follow: following symlinked dirs can escape cwd (e.g. a link to /
        -- leads into /sys , which never finishes). list the links themselves
        -- instead so symlinked dotfiles still show up
        '--type l',
        '--hidden',
        '--no-ignore-vcs',
        '--color never',
      }
      if not opts.all_filesystems then
        -- don't cross into other mounts (/proc, /sys, /dev, /run, drives in /mnt).
        -- note: on btrfs, subvolumes count as separate filesystems, so searching
        -- from / skips /home (@home); search ~ directly for that, or :FuzzyAll
        table.insert(args, '--one-file-system')
      end
      for _, dir in ipairs(excluded_dirs) do
        -- trailing slash: only exclude directories, not files with this name
        table.insert(args, '--exclude ' .. vim.fn.shellescape(dir .. '/'))
      end
      for _, ext in ipairs(excluded_exts) do
        table.insert(args, '--exclude ' .. vim.fn.shellescape('*.' .. ext))
        table.insert(args, '--exclude ' .. vim.fn.shellescape('*.' .. ext:upper()))
      end
      return table.concat(args, ' ')
    end

    --[[
    **************************************************************************
                          PAUSE / RESUME fd ON HIDE
    **************************************************************************
    --]]
    -- the default profile includes 'hide': <Esc> only hides the picker so
    -- <leader>fa can resume instantly , but that leaves fd crawling in the
    -- background. so on hide we SIGSTOP the fd feeding that picker (0 cpu, the
    -- hidden fzf keeps what it already has) , and SIGCONT it on resume so the
    -- search continues where it left off. if the hidden picker is thrown away
    -- (another picker opened) or nvim exits , the paused fd is SIGKILLed: a
    -- stopped process ignores SIGTERM , so it would otherwise leak forever.
    -- windows has no SIGSTOP , so there we just terminate fd on hide.
    local is_windows = vim.fn.has 'win32' == 1
    local paused_fd = {} -- fzf term bufnr -> list of paused fd pids
    local fzf_buf = nil -- term buffer of the picker currently on screen

    local function is_fd(pid)
      local ok, proc = pcall(vim.api.nvim_get_proc, pid)
      return ok and proc ~= nil and (proc.name == 'fd' or proc.name == 'fdfind')
    end

    -- fd processes anywhere under `pid` (fzf -> fzf-lua helper -> fd). other fd
    -- jobs , e.g. <leader>fp's dir suggestions, aren't under fzf so are left alone
    local function fd_pids_under(pid, acc)
      acc = acc or {}
      for _, child in ipairs(vim.api.nvim_get_proc_children(pid)) do
        if is_fd(child) then
          table.insert(acc, child)
        else
          fd_pids_under(child, acc)
        end
      end
      return acc
    end

    -- send `sig` to the fd processes paused for `buf` and forget them. pids are
    -- re-checked first in case one exited and its pid got reused
    local function signal_paused(buf, sig)
      for _, pid in ipairs(paused_fd[buf] or {}) do
        if is_fd(pid) then
          vim.uv.kill(pid, sig)
        end
      end
      paused_fd[buf] = nil
    end

    -- winopts.on_close: runs on hide as well as on close
    local function pause_fzf_fd()
      local buf = fzf_buf
      if not buf or not vim.api.nvim_buf_is_valid(buf) then
        return -- real close: buffer already deleted and fzf is gone with it
      end
      local ok, job_pid = pcall(vim.fn.jobpid, vim.bo[buf].channel)
      if not ok or job_pid <= 0 then
        return
      end
      local pids = fd_pids_under(job_pid)
      if #pids == 0 then
        return -- fd already finished, nothing to pause
      end
      for _, pid in ipairs(pids) do
        vim.uv.kill(pid, is_windows and 'sigterm' or 'sigstop')
      end
      if is_windows then
        return
      end
      paused_fd[buf] = pids
      -- hidden picker discarded (fzf-lua wipes its buffer) -> kill paused fd
      vim.api.nvim_create_autocmd('BufWipeout', {
        group = vim.api.nvim_create_augroup('FzfPausedFd' .. buf, { clear = true }),
        buffer = buf,
        once = true,
        callback = function()
          signal_paused(buf, 'sigkill')
        end,
      })
    end

    -- winopts.on_create: runs on open and again on unhide (resume)
    local function resume_fzf_fd(bufnr)
      fzf_buf = bufnr
      signal_paused(bufnr, 'sigcont') -- no-op unless this is a resumed picker
    end

    vim.api.nvim_create_autocmd('VimLeavePre', {
      group = vim.api.nvim_create_augroup('FzfPausedFdExit', { clear = true }),
      callback = function()
        for buf in pairs(paused_fd) do
          signal_paused(buf, 'sigkill')
        end
      end,
    })

    fzf.setup {
      { 'default' },
      fzf_opts = {
        ['--layout'] = 'default',
        ['--marker'] = '+',
        ['--gutter'] = ' ',
        ['--cycle'] = true,
      },
      winopts = {
        width = 0.8,
        height = 0.9,
        title_flags = false,
        on_create = function(e)
          vim.keymap.set('t', '<Esc>', '<Esc>', { buffer = true, nowait = true })
          resume_fzf_fd(e.bufnr)
        end,
        on_close = pause_fzf_fd,
        preview = {
          hidden = false,
          vertical = 'up:45%',
          horizontal = 'right:50%',
          layout = 'flex',
          flip_columns = 120,
          delay = 10,
          winopts = { number = false },
        },
      },
      hls = {
        normal = hl_validate 'TelescopeNormal',
        border = hl_validate 'TelescopeBorder',
        title = hl_validate 'TelescopePromptTitle',
        help_normal = hl_validate 'TelescopeNormal',
        help_border = hl_validate 'TelescopeBorder',
        preview_normal = hl_validate 'TelescopeNormal',
        preview_border = hl_validate 'TelescopeBorder',
        preview_title = hl_validate 'TelescopePreviewTitle',
        cursor = hl_validate 'Cursor',
        cursorline = hl_validate 'TelescopeSelection',
        cursorlinenr = hl_validate 'TelescopeSelection',
        search = hl_validate 'IncSearch',
      },
      fzf_colors = {
        ['fg'] = { 'fg', 'TelescopeNormal' },
        ['bg'] = { 'bg', 'TelescopeNormal' },
        ['hl'] = { 'fg', 'TelescopeMatching' },
        ['fg+'] = { 'fg', 'TelescopeSelection' },
        ['bg+'] = { 'bg', 'TelescopeSelection' },
        ['hl+'] = { 'fg', 'TelescopeMatching' },
        ['info'] = { 'fg', 'TelescopeMultiSelection' },
        ['border'] = { 'fg', 'TelescopeBorder' },
        ['gutter'] = '-1',
        ['query'] = { 'fg', 'TelescopePromptNormal' },
        ['prompt'] = { 'fg', 'TelescopePromptPrefix' },
        ['pointer'] = { 'fg', 'TelescopeSelectionCaret' },
        ['marker'] = { 'fg', 'TelescopeSelectionCaret' },
        ['header'] = { 'fg', 'TelescopeTitle' },
      },
      keymap = {
        builtin = {
          true,
          ['<C-d>'] = 'preview-page-down',
          ['<C-u>'] = 'preview-page-up',
        },
        fzf = {
          true,
          ['ctrl-d'] = 'preview-page-down',
          ['ctrl-u'] = 'preview-page-up',
          ['ctrl-q'] = 'select-all+accept',
        },
      },
      actions = {
        files = {
          ['enter'] = actions.file_edit_or_qf,
        },
      },
      buffers = {
        keymap = { builtin = { ['<C-d>'] = false } },
        actions = { ['ctrl-x'] = false, ['ctrl-d'] = { fn = actions.buf_del, reload = true } },
      },
      defaults = {
        git_icons = false,
        no_header_i = true,
      },
      ui_select = function(fzf_opts, items)
        return vim.tbl_deep_extend('force', fzf_opts, {
          prompt = ' ',
          winopts = { height = 0.30, width = 0.50 },
        }, fzf_opts.kind and fzf_opts.kind == 'codeaction' and {
          winopts = { height = 0.35, width = 0.60 },
        } or {})
      end,
      files = {
        cmd = files_cmd(),
        multiprocess = true,
        -- fd is paused on hide / resumed on unhide , see PAUSE / RESUME above
      },
      grep = {
        multiprocess = true,
        rg_opts = '--column --line-number --no-heading --color=always --smart-case --max-columns=4096 --colors "path:fg:white" --colors "line:fg:white"',
      },
    }

    vim.api.nvim_set_hl(0, 'FzfLuaBorder', { fg = colors.lighter_pink })
    vim.api.nvim_set_hl(0, 'FzfLuaPreviewBorder', { fg = colors.lighter_pink })
    vim.api.nvim_set_hl(0, 'FzfLuaTitle', { fg = colors.lighter_pink })
    vim.api.nvim_set_hl(0, 'FpZoxideArrow', { fg = '#ff5555', bold = true })

    --[[
    **************************************************************************
                                    KEYMAPS
    **************************************************************************
    --]]

    vim.keymap.set('n', '<leader>fh', fzf.help_tags, { desc = '[F]ind [H]elp' })
    vim.keymap.set('n', '<leader>fk', fzf.keymaps, { desc = '[F]ind [K]eymaps' })
    vim.keymap.set('n', '<leader>fc', fzf.commands, { desc = '[F]ind [C]ommands' })
    vim.keymap.set('n', '<leader>fs', fzf.builtin, { desc = '[F]ind [S]pecific finder' })
    vim.keymap.set('n', '<leader>fw', fzf.grep_cword, { desc = '[F]ind [W]ord under cursor' })

    vim.keymap.set('n', '<leader>fg', function()
      fzf.live_grep { cwd = vim.g.start_dir }
    end, { desc = '[F]ind by [G]rep' })

    vim.keymap.set('n', '<leader>fd', fzf.diagnostics_workspace, { desc = '[F]ind [D]iagnostics' })
    vim.keymap.set('n', '<leader>fa', fzf.resume, { desc = '[F]ind [A]gain' })

    --[[
    **************************************************************************
                          MEMORY PICKER (<leader>fm)
    **************************************************************************
    --]]
    -- memory used by nvim and its child processes (the statusline number),
    -- grouped by process name, biggest first. the preview lists each process
    -- in the group. note: memory is measured before the picker opens, and
    -- opening it discards a hidden picker (and the fzf/fd it was holding).
    -- <Enter> on a group offers to stop/kill it (with a warning first)
    local open_mem_picker -- forward declared, defined below

    local function short(s, n)
      return #s > n and (s:sub(1, n - 1) .. '…') or s
    end

    -- lsp clients whose server executable matches a group name
    local function lsp_clients_for(group_name)
      local clients = {}
      for _, client in ipairs(vim.lsp.get_clients()) do
        local cmd = client.config.cmd
        local exe = type(cmd) == 'table' and cmd[1] and vim.fs.basename(cmd[1]) or nil
        if exe == group_name or client.name == group_name then
          table.insert(clients, client)
        end
      end
      return clients
    end

    -- what killing `p` would do. returns nil, reason for processes that must
    -- never be killed, otherwise the warning to show before killing it
    local function kill_warning(p, ctx)
      if p.is_nvim then
        return nil, 'Cannot kill nvim (this editor). Exit normally instead with :qa'
      end
      if ctx.term_shell[p.pid] then
        return 'Shell of terminal '
          .. ctx.term_shell[p.pid]
          .. '. That terminal closes and everything running in it ends.'
      end
      -- inside a terminal? walk up the parents until a terminal shell or nvim
      local pid = p.ppid
      while pid and pid ~= ctx.nvim_pid do
        if ctx.term_shell[pid] then
          return 'Runs inside terminal '
            .. ctx.term_shell[pid]
            .. '. It ends and its unsaved state is lost (e.g. a claude session). The shell stays open.'
        end
        pid = ctx.by_pid[pid] and ctx.by_pid[pid].ppid
      end
      if ctx.lsp_group then
        return 'Part of LSP server '
          .. ctx.lsp_group
          .. '. Nvim sees it crash and its features stop until you :e the file.'
      end
      if p.name == 'fzf' or p.name == 'fd' or p.name == 'fdfind' or p.args:match 'fzf%-lua' then
        return 'Belongs to a search picker. Safe: that search (and <leader>fa resume) just stops.'
      end
      return 'Started by nvim or a plugin. Whatever uses it may break until it restarts (rerun the command or restart nvim).'
    end

    -- short result message in the regular message area (like :echo / print)
    local function report(what, killed, gone)
      local msg = what
      if gone > 0 then
        msg = msg .. string.format(' (%d had already exited)', gone)
      end
      vim.api.nvim_echo({ { msg } }, true, {})
    end

    local function procs_word(n)
      return n .. (n == 1 and ' process' or ' processes')
    end

    -- word-wrap `text` (paragraphs split on \n) to `width` columns
    local function wrap(text, width)
      local lines = {}
      for para in (text .. '\n'):gmatch '(.-)\n' do
        local line = ''
        for word in para:gmatch '%S+' do
          if line ~= '' and #line + 1 + #word > width then
            table.insert(lines, line)
            line = word
          else
            line = line == '' and word or (line .. ' ' .. word)
          end
        end
        table.insert(lines, line)
      end
      return lines
    end

    -- centered floating window showing `text`. `keys` maps lhs -> callback; any
    -- key in it closes the window first. leaving the window closes it too and
    -- runs `on_leave` (if given), so a confirm defaults to "no"
    local float_box_now -- defined below
    local function float_box(...)
      -- opened on the next tick: when called from a picker callback, fzf-lua
      -- may still be closing its window and moving focus, which would trigger
      -- WinLeave on our float right away
      local args = vim.F.pack_len(...) -- keeps nil arguments (e.g. no buttons)
      vim.schedule(function()
        float_box_now(vim.F.unpack_len(args))
      end)
    end

    -- `buttons`: optional list of { key, label } drawn as a centered row,
    -- e.g. { { 'Y', 'Yes' }, { 'N', 'No' } } -> '[Y] Yes     [N] No'
    float_box_now = function(text, title, buttons, title_hl, keys, on_leave)
      local pad = '  '
      local max_text = math.max(30, math.min(68, vim.o.columns - 12))
      local body = wrap(text, max_text)

      -- button row and where each key/label sits in it (for highlights)
      local row, marks = '', {}
      for i, b in ipairs(buttons or {}) do
        if i > 1 then
          row = row .. '     '
        end
        local key = '[' .. b[1] .. ']'
        table.insert(marks, { #row, #row + #key, #row + #key + 1 + #b[2] })
        row = row .. key .. ' ' .. b[2]
      end

      local inner = #row
      for _, l in ipairs(body) do
        inner = math.max(inner, vim.fn.strdisplaywidth(l))
      end
      local width = inner + 2 * #pad

      local lines = { '' }
      for _, l in ipairs(body) do
        table.insert(lines, pad .. l)
      end
      local row_line, row_col
      if #row > 0 then
        table.insert(lines, '')
        row_col = math.floor((width - #row) / 2)
        table.insert(lines, string.rep(' ', row_col) .. row)
        row_line = #lines - 1
      end
      table.insert(lines, '')

      local buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
      vim.bo[buf].modifiable = false
      vim.bo[buf].bufhidden = 'wipe'
      local ns = vim.api.nvim_create_namespace 'fzf_mem_dialog'
      for _, m in ipairs(marks) do
        vim.api.nvim_buf_set_extmark(buf, ns, row_line, row_col + m[1], {
          end_col = row_col + m[2],
          hl_group = 'Title',
        })
        vim.api.nvim_buf_set_extmark(buf, ns, row_line, row_col + m[2] + 1, {
          end_col = row_col + m[3],
          hl_group = 'Normal',
        })
      end

      local height = math.min(#lines, vim.o.lines - 4)
      local win = vim.api.nvim_open_win(buf, true, {
        relative = 'editor',
        width = width,
        height = height,
        row = math.floor((vim.o.lines - height) / 2) - 1,
        col = math.floor((vim.o.columns - width) / 2),
        style = 'minimal',
        border = 'rounded',
        title = { { ' ' .. title .. ' ', title_hl } },
        title_pos = 'center',
        zindex = 200,
      })
      -- same pink border as the fzf pickers
      vim.wo[win].winhighlight = 'FloatBorder:FzfLuaBorder,NormalFloat:Normal'
      vim.wo[win].cursorline = false

      local saved_guicursor = vim.o.guicursor
      local done = false
      local function close(cb)
        if done then
          return
        end
        done = true
        vim.o.guicursor = saved_guicursor
        if vim.api.nvim_win_is_valid(win) then
          vim.api.nvim_win_close(win, true)
        end
        if cb then
          vim.schedule(cb)
        end
      end
      for lhs, cb in pairs(keys) do
        vim.keymap.set('n', lhs, function()
          close(cb)
        end, { buffer = buf, nowait = true })
      end
      vim.api.nvim_create_autocmd('WinLeave', {
        buffer = buf,
        once = true,
        callback = function()
          close(on_leave)
        end,
      })

      -- hide the cursor while the dialog is focused: nvim draws no cursor when
      -- its highlight is fully transparent (blend = 100). done last, so an error
      -- above can never leave the cursor hidden. close() restores it
      vim.api.nvim_set_hl(0, 'FzfMemHiddenCursor', { blend = 100, nocombine = true })
      vim.o.guicursor = 'a:FzfMemHiddenCursor'
    end

    -- floating y/n prompt: runs on_yes only on 'y'. anything else is a no
    local function confirm(msg, on_yes)
      local noop = function() end
      float_box(msg, 'Warning', { { 'Y', 'Yes' }, { 'N', 'No' } }, 'WarningMsg', {
        y = on_yes,
        Y = on_yes,
        n = noop,
        N = noop,
        q = noop,
        ['<Esc>'] = noop,
      })
    end

    -- floating notice, closed with q / Esc / Enter (no buttons shown)
    local function notice(msg, title)
      float_box(msg, title or 'Notice', nil, 'WarningMsg', {
        q = false,
        ['<Esc>'] = false,
        ['<CR>'] = false,
      })
    end

    -- <Enter> on a group: pick what to stop/kill, confirm, do it
    local function kill_menu(g, ctx)
      ctx.lsp_group = nil
      local clients = lsp_clients_for(g.name)
      if #clients > 0 then
        ctx.lsp_group = g.name
      end

      local killable, protected = {}, {}
      for _, p in ipairs(g.procs) do
        table.insert(p.is_nvim and protected or killable, p)
      end

      local items = {}
      if #clients > 0 then
        table.insert(items, { kind = 'lsp' })
      end
      if #killable > 1 then
        table.insert(items, { kind = 'all' })
      end
      for _, p in ipairs(g.procs) do
        table.insert(items, { kind = 'one', proc = p })
      end

      local mem = require('core.utils').format_mem
      local function label(item)
        if item.kind == 'lsp' then
          return string.format(
            'Stop LSP %s (frees %s, :e restarts it)',
            g.name,
            procs_word(#g.procs)
          )
        elseif item.kind == 'all' then
          local total = 0
          for _, p in ipairs(killable) do
            total = total + p.rss
          end
          local note = #protected > 0 and ' (not this nvim)' or ''
          return string.format('Kill all %d processes, %s%s', #killable, mem(total), note)
        end
        local p = item.proc
        local tag = p.is_nvim and '[this nvim, cannot kill]  ' or ''
        return string.format('%6s  pid %-8d %s%s', mem(p.rss), p.pid, tag, short(p.args, 80))
      end

      local function handle(item)
        if not item then
          return
        end
        local utils_core = require 'core.utils'

        if item.kind == 'lsp' then
          local names = vim.tbl_map(function(c)
            return c.name
          end, clients)
          local msg = string.format(
            'Stop LSP %s (%s)?\n\nIts %s will exit, freeing the memory. Completion, diagnostics etc. stop in open buffers until you :e the file (or open another file of that type), which starts it again.',
            table.concat(names, ', '),
            g.name,
            procs_word(#g.procs)
          )
          confirm(msg, function()
            for _, c in ipairs(clients) do
              c:stop()
            end
            -- a clean stop doesn't always make the server exit (lua_ls keeps
            -- running once it's indexing), so anything left after 2s is terminated
            vim.defer_fn(function()
              local pids = vim.tbl_map(function(p)
                return p.pid
              end, g.procs)
              utils_core.terminate_pids(pids, function(killed, _)
                report(
                  'Stopped LSP '
                    .. g.name
                    .. (killed == 0 and '' or ' (forced: it did not exit on its own)'),
                  0,
                  0
                )
              end, 1000)
            end, 2000)
          end)
          return
        end

        if item.kind == 'one' then
          local p = item.proc
          local warning, refusal = kill_warning(p, ctx)
          if not warning then
            notice(refusal, 'Cannot kill')
            return
          end
          local msg =
            string.format('Kill %s (pid %d, %s)?\n\n%s', p.name, p.pid, mem(p.rss), warning)
          confirm(msg, function()
            utils_core.terminate_pids({ p.pid }, function(_, gone)
              local fmt = gone > 0 and '%s (pid %d) had already exited' or 'Killed %s (pid %d)'
              report(string.format(fmt, p.name, p.pid), 0, 0)
            end)
          end)
          return
        end

        -- kill all: show every distinct warning in the group
        local warnings, seen = {}, {}
        for _, p in ipairs(killable) do
          local w = kill_warning(p, ctx)
          if w and not seen[w] then
            seen[w] = true
            table.insert(warnings, '- ' .. w)
          end
        end
        local msg = string.format(
          'Kill all %d %s processes?%s\n\n%s',
          #killable,
          g.name,
          #protected > 0 and ' (this nvim is skipped, it cannot be killed)' or '',
          table.concat(warnings, '\n')
        )
        confirm(msg, function()
          local pids = vim.tbl_map(function(p)
            return p.pid
          end, killable)
          utils_core.terminate_pids(pids, function(killed, gone)
            local word = killed == 1 and 'process' or 'processes'
            report(string.format('Killed %d %s %s', killed, g.name, word), 0, gone)
          end)
        end)
      end

      -- a single process needs no menu: straight to the confirm (or the
      -- cannot-kill notice). for an lsp that's the clean stop, so :e restarts it
      if #g.procs == 1 then
        handle(#clients > 0 and { kind = 'lsp' } or { kind = 'one', proc = g.procs[1] })
        return
      end
      vim.ui.select(items, {
        prompt = 'Stop/kill ' .. g.name .. '> ',
        format_item = label,
      }, handle)
    end

    open_mem_picker = function()
      local core_utils = require 'core.utils'
      local procs = core_utils.mem_processes()
      if #procs == 0 then
        notice('Memory usage is not available on this platform.', 'Memory')
        return
      end

      -- context for kill warnings: processes by pid and terminal shells
      local ctx = { nvim_pid = vim.fn.getpid(), by_pid = {}, term_shell = {} }
      for _, p in ipairs(procs) do
        ctx.by_pid[p.pid] = p
      end
      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buftype == 'terminal' then
          local ok, pid = pcall(vim.fn.jobpid, vim.bo[buf].channel)
          if ok and pid > 0 then
            ctx.term_shell[pid] =
              string.format('#%d (%s)', buf, short(vim.api.nvim_buf_get_name(buf), 50))
          end
        end
      end

      local groups, by_name, total = {}, {}, 0
      for _, p in ipairs(procs) do
        local g = by_name[p.name]
        if not g then
          g = { name = p.name, rss = 0, procs = {} }
          by_name[p.name] = g
          table.insert(groups, g)
        end
        g.rss = g.rss + p.rss
        total = total + p.rss
        table.insert(g.procs, p)
      end
      table.sort(groups, function(a, b)
        return a.rss > b.rss
      end)

      local entries, group_of = {}, {} -- group_of: entry line -> group
      for _, g in ipairs(groups) do
        table.sort(g.procs, function(a, b)
          return a.rss > b.rss
        end)
        local count = #g.procs > 1 and (' x' .. #g.procs) or ''
        local entry = string.format('%6s  %s%s', core_utils.format_mem(g.rss), g.name, count)
        group_of[vim.trim(entry)] = g -- trimmed: fzf may strip the padding
        table.insert(entries, entry)
      end

      fzf.fzf_exec(entries, {
        prompt = 'Memory> ',
        winopts = { title = ' Memory: ' .. core_utils.format_mem(total) .. ' total ' },
        fzf_opts = {
          ['--no-sort'] = true,
          ['--header'] = '\n<Enter> stop/kill', -- blank line above the hint
        },
        preview = function(items)
          local g = group_of[vim.trim(items[1] or '')]
          if not g then
            return {}
          end
          local lines = {
            string.format(
              '%s  %s  (%d %s)',
              g.name,
              core_utils.format_mem(g.rss),
              #g.procs,
              #g.procs == 1 and 'process' or 'processes'
            ),
            '',
          }
          for _, p in ipairs(g.procs) do
            local tag = p.is_nvim and '  [this nvim]' or ''
            table.insert(
              lines,
              string.format('%6s  pid %-8d%s', core_utils.format_mem(p.rss), p.pid, tag)
            )
            table.insert(lines, '        ' .. p.args)
          end
          return lines
        end,
        actions = {
          ['enter'] = function(selected)
            local g = group_of[vim.trim((selected or {})[1] or '')]
            if not g then
              return
            end
            local function open_menu()
              kill_menu(g, ctx)
            end
            -- closing this picker queues a stopinsert in fzf-lua. opening the
            -- menu right away would land it in normal mode, so wait for that
            -- first (same as fzf-lua's own actions.run_builtin)
            if _G.fzf_lua_stopinsert_hack then
              _G.fzf_lua_stopinsert_hack(open_menu)
            else
              vim.schedule(open_menu)
            end
          end,
        },
      })
    end

    vim.keymap.set('n', '<leader>fm', function()
      open_mem_picker()
    end, { desc = '[F]ind [M]emory usage' })
    vim.keymap.set('n', '<leader>fr', fzf.oldfiles, { desc = '[F]ind [R]ecently viewed' })
    vim.keymap.set('n', '<leader><leader>', fzf.buffers, { desc = '[ ] Find existing buffers' })

    vim.keymap.set('n', '<leader>fe', function()
      fzf.files { cwd = vim.fn.stdpath 'config', prompt = 'Find Files in Neovim Config> ' }
    end, { desc = '[F]ind N[e]ovim files' })

    vim.keymap.set('n', '<leader>fn', function()
      if vim.g.local_settings and vim.g.local_settings.notes_path then
        fzf.files { cwd = vim.g.local_settings.notes_path, prompt = 'Find Code Notes> ' }
      else
        print 'ERROR (fuzzy.lua): notes_path not set'
      end
    end, { desc = '[F]ind [N]otes' })

    vim.keymap.set('n', '<leader>ff', function()
      fzf.files { cwd = vim.g.start_dir }
    end, { desc = '[F]ind [F]iles' })

    -- rarely needed, so no keymap: fuzzy find the whole pc from / across every
    -- mount (/home, /mnt drives, /proc, /sys, ...). slow, fd pauses on hide
    vim.api.nvim_create_user_command('FuzzyAll', function()
      -- WARN: don't be an idiot , why do you even need this ?
      fzf.files {
        cwd = '/',
        cmd = files_cmd { all_filesystems = true },
        prompt = 'Find Files in Whole PC> ',
      }
    end, { desc = 'Fuzzy find files across the whole pc from /' })

    -- vim.keymap.set('n', '<leader>fp', function()
    --   local utils_core = require 'core.utils'
    --   local buf = vim.api.nvim_create_buf(false, true)
    --   local width = 60
    --   local height = 1
    --   local row = math.floor((vim.o.lines - height) / 2)
    --   local col = math.floor((vim.o.columns - width) / 2)
    --
    --   local win = vim.api.nvim_open_win(buf, true, {
    --     relative = 'editor',
    --     width = width,
    --     height = height,
    --     row = row,
    --     col = col,
    --     style = 'minimal',
    --     border = 'rounded',
    --     title = ' Search Path ',
    --     title_pos = 'center',
    --   })
    --
    --   vim.api.nvim_win_set_option(win, 'winhl', 'FloatBorder:FzfLuaBorder')
    --   vim.api.nvim_buf_set_option(buf, 'buftype', 'prompt')
    --   vim.fn.prompt_setprompt(buf, '> ')
    --   vim.api.nvim_buf_set_option(buf, 'modified', false)
    --   vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
    --   vim.cmd 'startinsert'
    --
    --   vim.keymap.set('i', '<CR>', function()
    --     local input = vim.api.nvim_buf_get_lines(buf, 0, -1, false)[1]
    --     input = input:gsub('^> ', '')
    --     vim.api.nvim_win_close(win, true)
    --
    --     local search_path
    --     if input == '' or input == '/' then
    --       search_path = '/'
    --     elseif input == '.' then
    --       search_path = utils_core.get_git_root(true)
    --       if search_path == '' then
    --         search_path = vim.fn.fnamemodify(vim.fn.expand '%:p', ':h')
    --       end
    --     else
    --       local handle = io.popen('zoxide query ' .. input .. ' 2>/dev/null')
    --       if handle then
    --         local result = handle:read '*a'
    --         handle:close()
    --         search_path = result:gsub('%s+$', '')
    --         if search_path == '' then
    --           search_path = vim.fn.expand(input)
    --         end
    --       else
    --         search_path = vim.fn.expand(input)
    --       end
    --     end
    --
    --     if vim.fn.isdirectory(search_path) == 0 then
    --       vim.notify('Path does not exist: ' .. search_path, vim.log.levels.ERROR)
    --       return
    --     end
    --
    --     fzf.files { cwd = search_path, prompt = 'Find Files in: ' .. search_path .. '> ' }
    --     vim.schedule(function()
    --       vim.cmd 'startinsert'
    --     end)
    --   end, { buffer = buf })
    --
    --   vim.keymap.set('i', '<Esc>', function()
    --     vim.api.nvim_win_close(win, true)
    --   end, { buffer = buf })
    -- end, { desc = '[F]ind files in specific [P]ath (with zoxide)' })

    vim.keymap.set('n', '<leader>fp', function()
      local root = vim.g.start_dir or '.'
      local fd_job = nil -- the fd|fzf job for picker instance

      local input_buf = vim.api.nvim_create_buf(false, true)
      local results_buf = vim.api.nvim_create_buf(false, true)
      local zoxide_buf = vim.api.nvim_create_buf(false, true)

      local editor_width = vim.o.columns
      local editor_height = vim.o.lines
      local width = 50
      local input_height = 1
      local results_height = 10
      local zoxide_height = 3
      local total_height = zoxide_height + 2 + input_height + 2 + results_height + 2
      local col = math.floor((editor_width - width) / 2)
      local row = math.floor((editor_height - total_height) / 2)

      local zoxide_row = row
      local input_row = zoxide_row + zoxide_height + 2
      local results_row = input_row + input_height + 2

      local zoxide_win = vim.api.nvim_open_win(zoxide_buf, false, {
        relative = 'editor',
        width = width,
        height = zoxide_height,
        row = zoxide_row,
        col = col,
        style = 'minimal',
        border = 'rounded',
        title = ' match ',
        title_pos = 'center',
        zindex = 51,
      })

      local input_win = vim.api.nvim_open_win(input_buf, true, {
        relative = 'editor',
        width = width,
        height = input_height,
        row = input_row,
        col = col,
        style = 'minimal',
        border = 'rounded',
        title = ' zoxide ',
        title_pos = 'center',
        zindex = 51,
      })

      local results_win = vim.api.nvim_open_win(results_buf, false, {
        relative = 'editor',
        width = width,
        height = results_height,
        row = results_row,
        col = col,
        style = 'minimal',
        border = 'rounded',
        title = ' fd ',
        title_pos = 'center',
        zindex = 50,
      })

      vim.api.nvim_win_set_option(input_win, 'winhl', 'FloatBorder:FzfLuaBorder')
      vim.api.nvim_win_set_option(
        results_win,
        'winhl',
        'FloatBorder:FzfLuaBorder,Normal:TelescopeNormal'
      )
      vim.api.nvim_win_set_option(
        zoxide_win,
        'winhl',
        'FloatBorder:FzfLuaBorder,Normal:TelescopeNormal'
      )

      vim.api.nvim_buf_set_option(input_buf, 'buftype', 'prompt')
      vim.api.nvim_buf_set_option(input_buf, 'bufhidden', 'wipe')
      vim.api.nvim_buf_set_option(results_buf, 'bufhidden', 'wipe')
      vim.api.nvim_buf_set_option(results_buf, 'modifiable', true)
      vim.api.nvim_buf_set_option(zoxide_buf, 'bufhidden', 'wipe')
      vim.api.nvim_buf_set_option(zoxide_buf, 'modifiable', true)
      vim.fn.prompt_setprompt(input_buf, '> ')

      local selected_idx = 1
      local current_results = {}

      local function stop_fd_job()
        if fd_job then
          pcall(vim.fn.jobstop, fd_job) -- pcall: job may have already exited
          fd_job = nil
        end
      end

      -- input_buf is bufhidden=wipe, so this catches every exit path (q, <Esc>, :q, <CR>, window jumps)
      vim.api.nvim_create_autocmd('BufWipeout', {
        buffer = input_buf,
        once = true,
        callback = stop_fd_job,
      })

      local function close_all()
        stop_fd_job()
        pcall(vim.api.nvim_win_close, input_win, true)
        pcall(vim.api.nvim_win_close, results_win, true)
        pcall(vim.api.nvim_win_close, zoxide_win, true)
      end

      local function update_results_display()
        local lines = {}
        for i, path in ipairs(current_results) do
          if i == selected_idx then
            table.insert(lines, '> ' .. path)
          else
            table.insert(lines, '  ' .. path)
          end
        end
        vim.api.nvim_buf_set_option(results_buf, 'modifiable', true)
        vim.api.nvim_buf_set_lines(results_buf, 0, -1, false, lines)
        vim.api.nvim_buf_clear_namespace(results_buf, -1, 0, -1)
        if #current_results > 0 then
          vim.api.nvim_buf_add_highlight(
            results_buf,
            -1,
            'TelescopeSelection',
            selected_idx - 1,
            0,
            -1
          )
          vim.api.nvim_buf_add_highlight(results_buf, -1, 'FpZoxideArrow', selected_idx - 1, 0, 2)
        end
      end

      local function get_input()
        local lines = vim.api.nvim_buf_get_lines(input_buf, 0, -1, false)
        local text = lines[1] or ''
        return text:gsub('^> ', '')
      end

      local function refresh_results(query)
        selected_idx = 1
        local cmd
        if query == '' then
          cmd = 'fd --type d --hidden . ' .. root .. ' | head -10'
        else
          cmd = 'fd --type d --hidden . '
            .. root
            .. ' | fzf --filter='
            .. vim.fn.shellescape(query)
            .. ' | head -10'
        end
        stop_fd_job() -- kill the previous keystroke's crawl before starting a new one
        local job
        job = vim.fn.jobstart(cmd, {
          stdout_buffered = true,
          on_stdout = function(_, data)
            if not data or job ~= fd_job then
              return -- stale job: ignore so older results can't overwrite newer ones
            end
            current_results = {}
            for _, line in ipairs(data) do
              if line ~= '' then
                table.insert(current_results, line)
              end
            end
            vim.schedule(function()
              if not vim.api.nvim_buf_is_valid(results_buf) then
                return
              end
              update_results_display()
            end)
          end,
          on_exit = function()
            if job == fd_job then
              fd_job = nil
            end
          end,
        })
        fd_job = job
      end

      local function refresh_zoxide(query)
        if query == '' then
          vim.schedule(function()
            if not vim.api.nvim_buf_is_valid(zoxide_buf) then
              return
            end
            vim.api.nvim_buf_set_option(zoxide_buf, 'modifiable', true)
            vim.api.nvim_buf_set_lines(zoxide_buf, 0, -1, false, { '', '', '' })
            vim.api.nvim_buf_clear_namespace(zoxide_buf, -1, 0, -1)
          end)
          return
        end
        local words = vim.split(query, '%s+', { trimempty = true })
        local kw = table.concat(vim.tbl_map(vim.fn.shellescape, words), ' ')
        vim.fn.jobstart('zoxide query --list -- ' .. kw .. ' 2>/dev/null | head -3', {
          stdout_buffered = true,
          on_stdout = function(_, data)
            vim.schedule(function()
              if not vim.api.nvim_buf_is_valid(zoxide_buf) then
                return
              end
              local matches = {}

              -- prioritize literal path first
              local expanded = vim.fn.expand(query)
              if vim.fn.isdirectory(expanded) == 1 then
                table.insert(matches, expanded)
              end

              if data then
                for _, line in ipairs(data) do
                  if line ~= '' and line ~= expanded then
                    table.insert(matches, line)
                    if #matches >= 3 then
                      break
                    end
                  end
                end
              end

              -- reverse so worst at top, best at bottom
              local reversed = {}
              for i = #matches, 1, -1 do
                table.insert(reversed, matches[i])
              end

              -- pad to 3 with empty lines at top
              local lines = {}
              local padding = 3 - #reversed
              for _ = 1, padding do
                table.insert(lines, '')
              end
              for i, match in ipairs(reversed) do
                if i == #reversed then
                  table.insert(lines, '> ' .. match)
                else
                  table.insert(lines, '  ' .. match)
                end
              end

              vim.api.nvim_buf_set_option(zoxide_buf, 'modifiable', true)
              vim.api.nvim_buf_set_lines(zoxide_buf, 0, -1, false, lines)
              vim.api.nvim_buf_clear_namespace(zoxide_buf, -1, 0, -1)
              vim.api.nvim_buf_add_highlight(zoxide_buf, -1, 'FpZoxideArrow', #lines - 1, 0, 2)
            end)
          end,
        })
      end

      local function do_zoxide(query)
        if query == '' then
          return
        end
        close_all()
        vim.schedule(function()
          -- prioritize literal path first
          local expanded = vim.fn.expand(query)
          if vim.fn.isdirectory(expanded) == 1 then
            fzf.files { cwd = expanded }
            return
          end
          -- fallback to zoxide
          local words = vim.split(query, '%s+', { trimempty = true })
          local kw = table.concat(vim.tbl_map(vim.fn.shellescape, words), ' ')
          local handle = io.popen('zoxide query -- ' .. kw .. ' 2>/dev/null')
          if handle then
            local result = handle:read '*a'
            handle:close()
            local path = result:gsub('%s+$', '')
            if path ~= '' and vim.fn.isdirectory(path) == 1 then
              fzf.files { cwd = path }
            else
              vim.notify('No match for: ' .. query, vim.log.levels.WARN)
            end
          end
        end)
      end

      vim.api.nvim_create_autocmd({ 'TextChangedI', 'TextChanged' }, {
        buffer = input_buf,
        callback = function()
          local q = get_input()
          refresh_results(q)
          refresh_zoxide(q)
        end,
      })

      vim.keymap.set('i', '<CR>', function()
        do_zoxide(get_input())
      end, { buffer = input_buf })

      vim.keymap.set('i', '<C-y>', function()
        if current_results[selected_idx] then
          local val = current_results[selected_idx]
          vim.api.nvim_buf_set_lines(input_buf, 0, -1, false, { '> ' .. val })
          vim.api.nvim_win_set_cursor(input_win, { 1, #val + 2 })
          refresh_zoxide(val)
        end
      end, { buffer = input_buf })

      vim.keymap.set('i', '<Down>', function()
        if selected_idx < #current_results then
          selected_idx = selected_idx + 1
          update_results_display()
        end
      end, { buffer = input_buf })

      vim.keymap.set('i', '<Up>', function()
        if selected_idx > 1 then
          selected_idx = selected_idx - 1
          update_results_display()
        end
      end, { buffer = input_buf })

      vim.keymap.set('i', '<Esc>', function()
        vim.cmd 'stopinsert'
      end, { buffer = input_buf })

      vim.keymap.set('n', '<Esc>', function()
        close_all()
      end, { buffer = input_buf })

      vim.keymap.set('n', 'q', function()
        close_all()
      end, { buffer = input_buf })

      vim.cmd 'startinsert'
      refresh_results ''
      refresh_zoxide ''
    end, { desc = '[F]ind files in specific [P]ath (with zoxide)' })

    --
    vim.keymap.set('n', '<leader>/', function()
      fzf.blines { previewer = false, winopts = { height = 0.40, width = 0.60 } }
    end, { desc = '[/] Fuzzily search in current buffer' })

    vim.keymap.set('n', '<leader>f/', function()
      local open_files = {}
      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(buf) then
          local name = vim.api.nvim_buf_get_name(buf)
          if name ~= '' then
            table.insert(open_files, name)
          end
        end
      end
      fzf.live_grep {
        prompt = 'Live Grep in Open Files> ',
        search_paths = open_files,
      }
    end, { desc = '[F]ind [/] in Open Files' })
  end,
}
