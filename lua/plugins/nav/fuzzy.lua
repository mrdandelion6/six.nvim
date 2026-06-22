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
        on_create = function()
          vim.keymap.set('t', '<Esc>', '<Esc>', { buffer = true, nowait = true })
        end,
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
        cmd = table.concat({
          'rg',
          '--files',
          '--follow',
          '--hidden',
          '--no-ignore-vcs',
          '--max-filesize',
          '10M',
          '--glob',
          '!.git/',
          '--glob',
          '!lib/',
          '--glob',
          '!node_modules/',
          '--glob',
          '!target/',
          '--glob',
          '!dist/',
          '--glob',
          '!build/',
          '--glob',
          '!.tex/',
          '--glob',
          '!.cache/',
          '--glob',
          '!.npm/',
          '--glob',
          '!.cargo/',
        }, ' '),
        multiprocess = true,
      },
      grep = {
        multiprocess = true,
        rg_opts = '--column --line-number --no-heading --color=always --smart-case --max-columns=4096 --colors "path:fg:white" --colors "line:fg:white"',
      },
    }

    fzf.register_ui_select()
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
    vim.keymap.set('n', '<leader>fs', fzf.builtin, { desc = '[F]ind [S]pecific finder' })
    vim.keymap.set('n', '<leader>fw', fzf.grep_cword, { desc = '[F]ind [W]ord under cursor' })

    vim.keymap.set('n', '<leader>fg', function()
      fzf.live_grep { cwd = vim.g.start_dir }
    end, { desc = '[F]ind by [G]rep' })

    vim.keymap.set('n', '<leader>fd', fzf.diagnostics_workspace, { desc = '[F]ind [D]iagnostics' })
    vim.keymap.set('n', '<leader>fa', fzf.resume, { desc = '[F]ind [A]gain' })
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
      vim.api.nvim_win_set_option(results_win, 'winhl', 'FloatBorder:FzfLuaBorder,Normal:TelescopeNormal')
      vim.api.nvim_win_set_option(zoxide_win, 'winhl', 'FloatBorder:FzfLuaBorder,Normal:TelescopeNormal')

      vim.api.nvim_buf_set_option(input_buf, 'buftype', 'prompt')
      vim.api.nvim_buf_set_option(input_buf, 'bufhidden', 'wipe')
      vim.api.nvim_buf_set_option(results_buf, 'bufhidden', 'wipe')
      vim.api.nvim_buf_set_option(results_buf, 'modifiable', true)
      vim.api.nvim_buf_set_option(zoxide_buf, 'bufhidden', 'wipe')
      vim.api.nvim_buf_set_option(zoxide_buf, 'modifiable', true)
      vim.fn.prompt_setprompt(input_buf, '> ')

      local selected_idx = 1
      local current_results = {}

      local function close_all()
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
          vim.api.nvim_buf_add_highlight(results_buf, -1, 'TelescopeSelection', selected_idx - 1, 0, -1)
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
          cmd = 'fd --type d --hidden --follow . ' .. root .. ' | head -10'
        else
          cmd = 'fd --type d --hidden --follow . ' .. root .. ' | fzf --filter=' .. vim.fn.shellescape(query) .. ' | head -10'
        end
        vim.fn.jobstart(cmd, {
          stdout_buffered = true,
          on_stdout = function(_, data)
            if not data then
              return
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
        })
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
