return {
  'nvim-treesitter/nvim-treesitter',
  branch = 'main',
  lazy = false, -- the main branch does not support lazy-loading

  build = ':TSUpdate',
  dependencies = {
    {
      'nvim-treesitter/nvim-treesitter-textobjects',
      branch = 'main',
    },
  },

  config = function()
    local ts = require 'nvim-treesitter'

    -- parsers -----------------------------------------------------------------
    ts.install {
      'bash',
      'c',
      'diff',
      'html',
      'lua',
      'luadoc',
      'markdown',
      'markdown_inline',
      'query',
      'vim',
      'vimdoc',
      'python',
      'javascript',
      'json',
      'yaml',
    }

    -- highlight / indent / auto_install ---------------------------------------
    local available = nil -- cached list of installable parsers

    local function enable_features(buf)
      if not vim.api.nvim_buf_is_valid(buf) then
        return
      end
      if pcall(vim.treesitter.start, buf) then
        vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
      end
    end

    vim.api.nvim_create_autocmd('FileType', {
      group = vim.api.nvim_create_augroup('treesitter_features', { clear = true }),
      callback = function(args)
        local buf = args.buf
        local lang = vim.treesitter.language.get_lang(args.match)
        if not lang then
          return
        end

        -- Parser already present: just start it.
        if vim.treesitter.language.add(lang) then
          enable_features(buf)
          return
        end

        -- Replaces `auto_install = true`: install a missing parser if
        -- nvim-treesitter knows about it, then start it in this buffer.
        available = available or ts.get_available()
        if vim.list_contains(available, lang) then
          ts.install(lang):await(function(err)
            if not err then
              vim.schedule(function()
                enable_features(buf)
              end)
            end
          end)
        end
      end,
    })

    -- textobjects -------------------------------------------------------------
    require('nvim-treesitter-textobjects').setup {
      select = { lookahead = true },
      move = { set_jumps = true },
    }

    local ts_select = require 'nvim-treesitter-textobjects.select'

    vim.keymap.set({ 'x', 'o' }, 'af', function()
      ts_select.select_textobject('@function.outer', 'textobjects')
    end, { desc = '[A]round [F]unction' })

    vim.keymap.set({ 'x', 'o' }, 'ac', function()
      ts_select.select_textobject('@code_cell.outer', 'textobjects')
    end, { desc = '[A]round [C]ode cell' })

    -- move between functions and code cells
    local ts_move = require 'nvim-treesitter-textobjects.move'
    local moves = {
      { ']f', 'goto_next_start', '@function.outer', 'Next [F]unction start' },
      { ']F', 'goto_next_end', '@function.outer', 'Next [F]unction end' },
      { '[f', 'goto_previous_start', '@function.outer', 'Previous [F]unction start' },
      { '[F', 'goto_previous_end', '@function.outer', 'Previous [F]unction end' },
      { ']]', 'goto_next_start', '@code_cell.inner', 'Next [C]ode cell start' },
      { '][', 'goto_next_end', '@code_cell.inner', 'Next [C]ode cell end' },
      { '[[', 'goto_previous_start', '@code_cell.inner', 'Previous [C]ode cell start' },
    }

    -- goto_previous_end gets stuck on @code_cell.inner because the node ends at
    -- col 0 of the next line. do it by hand: jump to the last character of the
    -- closest cell that ends before the cursor.
    local function goto_previous_cell_end()
      local ok, parser = pcall(vim.treesitter.get_parser, 0)
      if not ok or not parser then
        return
      end
      local query = vim.treesitter.query.get(parser:lang(), 'textobjects')
      if not query then
        return
      end
      local cur = vim.api.nvim_win_get_cursor(0)
      local row, col = cur[1] - 1, cur[2]
      local best
      for _, tree in ipairs(parser:parse()) do
        for id, node in query:iter_captures(tree:root(), 0) do
          if query.captures[id] == 'code_cell.inner' then
            local _, _, er, ec = node:range()
            if ec == 0 then -- ends at start of next line: use end of previous line
              er = er - 1
              ec = #vim.api.nvim_buf_get_lines(0, er, er + 1, false)[1]
            end
            ec = math.max(ec - 1, 0)
            local before = er < row or (er == row and ec < col)
            if before and (not best or er > best[1] or (er == best[1] and ec > best[2])) then
              best = { er, ec }
            end
          end
        end
      end
      if best then
        vim.cmd "normal! m'"
        vim.api.nvim_win_set_cursor(0, { best[1] + 1, best[2] })
      end
    end

    local function set_moves(buf)
      for _, m in ipairs(moves) do
        local lhs, fn, query, desc = m[1], m[2], m[3], m[4]
        vim.keymap.set({ 'n', 'x', 'o' }, lhs, function()
          ts_move[fn](query, 'textobjects')
        end, { desc = desc, buffer = buf })
      end
      vim.keymap.set(
        { 'n', 'x', 'o' },
        '[]',
        goto_previous_cell_end,
        { desc = 'Previous [C]ode cell end', buffer = buf }
      )
    end
    set_moves()

    -- nvim's runtime ftplugin/markdown.lua sets buffer-local ]] / [[ (jump to
    -- heading) which shadow the global ones. re-apply ours buffer-locally,
    -- scheduled so it runs after the ftplugin.
    vim.api.nvim_create_autocmd('FileType', {
      group = vim.api.nvim_create_augroup('treesitter_cell_moves', { clear = true }),
      pattern = { 'markdown', 'quarto' },
      callback = function(args)
        vim.schedule(function()
          if vim.api.nvim_buf_is_valid(args.buf) then
            set_moves(args.buf)
          end
        end)
      end,
    })

    local function set_layout_textobjects()
      if vim.g.local_settings == nil then
        print 'ERROR (treesitter.lua): vim.g.local_settings is nil'
        return
      end

      local layout = vim.g.local_settings.keyboard_layout
      if layout == nil then
        print 'ERROR (treesitter.lua): vim.g.local_settings.keyboard_layout is nil'
        return
      end

      local new_prefix
      local old_prefix

      if layout == 'colemak' then
        new_prefix = 'l'
        old_prefix = 'i'
      elseif layout == 'qwerty' then
        new_prefix = 'i'
        old_prefix = 'l'
      else
        return
      end

      pcall(vim.keymap.del, { 'x', 'o' }, old_prefix .. 'f')
      pcall(vim.keymap.del, { 'x', 'o' }, old_prefix .. 'c')

      local select = require 'nvim-treesitter-textobjects.select'

      vim.keymap.set({ 'x', 'o' }, new_prefix .. 'f', function()
        select.select_textobject('@function.inner', 'textobjects')
      end, { desc = 'Inside Function' })

      vim.keymap.set({ 'x', 'o' }, new_prefix .. 'c', function()
        select.select_textobject('@code_cell.inner', 'textobjects')
      end, { desc = 'Inside Code cell' })
    end

    local group = vim.api.nvim_create_augroup('treesitter_keyboard_layout', { clear = true })

    vim.api.nvim_create_autocmd('User', {
      group = group,
      pattern = 'KeyboardLayoutChanged',
      callback = set_layout_textobjects,
    })

    set_layout_textobjects()
  end,
}
