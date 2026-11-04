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
