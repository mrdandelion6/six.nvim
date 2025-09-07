-- oil.lua
-- a vim-vinegar like file explorer that lets you edit your filesystem like a normal neovim buffer

return {
  'stevearc/oil.nvim',
  opts = {},
  dependencies = { 'nvim-tree/nvim-web-devicons' }, -- use if prefer nvim-web-devicons

  keys = {
    {
      '<leader>e',
      function()
        require('oil').open()
      end,
      desc = '[E]xplore Current File Directory',
    },
    {
      '<leader>E',
      function()
        require('oil').open(vim.fn.getcwd())
      end,
      desc = '[E]xplore Project Directory',
    },
  },

  config = function()
    require('oil').setup {
      -- oil will take over directory buffers (e.g. `vim .` or `:e src/`)
      default_file_explorer = true,

      -- id is automatically added at the beginning, and name at the end
      -- see :help oil-columns
      columns = {
        'icon',
        -- "permissions",
        'size',
        'mtime',
      },

      -- buffer-local options to use for oil buffers
      buf_options = {
        buflisted = false,
        bufhidden = 'hide',
      },

      -- window-local options to use for oil buffers
      win_options = {
        wrap = false,
        signcolumn = 'no',
        cursorcolumn = false,
        foldcolumn = '0',
        spell = false,
        list = false,
        conceallevel = 3,
        concealcursor = 'nvic',
      },

      -- send deleted files to the trash instead of permanently deleting them (:help oil-trash)
      delete_to_trash = true,

      -- skip the confirmation popup for simple operations (:help oil.skip-confirm)
      skip_confirm_for_simple_edits = true,

      -- selecting a new/moved/renamed file or directory will prompt you to save changes first
      -- (:help prompt_save_on_select_new_entry)
      prompt_save_on_select_new_entry = true,

      -- oil will automatically delete hidden buffers after this delay
      -- you can set the delay to false to disable cleanup entirely
      -- note that the cleanup process only starts when you enter oil again,
      -- so deleted buffers may remain active if you never open oil again
      cleanup_delay_ms = 2000,
      lsp_file_methods = {
        -- time to wait for lsp file operations to complete before skipping
        timeout_ms = 1000,
        -- set to true to autosave buffers that are updated with lsp willrenamefiles
        -- set to "unmodified" to only autosave unmodified buffers
        autosave_changes = false,
      },

      -- constrain the cursor to the editable parts of the oil buffer
      -- set to `false` to disable, or "name" to keep it on the file names
      constrain_cursor = 'editable',

      -- set to true to watch the filesystem for changes and reload oil
      experimental_watch_for_changes = false,

      -- keymaps in oil buffer. can be any value that `vim.keymap.set` accepts or a table of keymap
      -- options with a `callback` (e.g. { callback = function() ... end, desc = "", mode = "n" })
      -- additionally, if it is a string that matches "action.<name>",
      -- it will use the mapping at require("oil.actions").<name>
      -- set to `false` to remove a keymap
      -- see :help oil-actions for a list of all available actions
      keymaps = {
        ['g?'] = 'actions.show_help',
        ['<CR>'] = 'actions.select',
        ['<C-s>'] = { 'actions.select', opts = { vertical = true }, desc = 'open the entry in a vertical split' },
        ['<C-h>'] = { 'actions.select', opts = { horizontal = true }, desc = 'open the entry in a horizontal split' },
        ['<C-t>'] = { 'actions.select', opts = { tab = true }, desc = 'open the entry in new tab' },
        ['<C-p>'] = 'actions.preview',
        ['<C-c>'] = 'actions.close',
        ['<C-l>'] = 'actions.refresh',
        ['-'] = 'actions.parent',
        ['_'] = 'actions.open_cwd',
        ['`'] = 'actions.cd',
        ['~'] = { 'actions.cd', opts = { scope = 'tab' }, desc = ':tcd to the current oil directory' },
        ['gs'] = 'actions.change_sort',
        ['gx'] = 'actions.open_external',
        ['g.'] = 'actions.toggle_hidden',
        ['g\\'] = 'actions.toggle_trash',
      },

      -- set to false to disable all of the above keymaps
      use_default_keymaps = true,

      view_options = {
        -- show files and directories that start with "."
        show_hidden = true,
        -- this function defines what is considered a "hidden" file
        is_hidden_file = function(name, bufnr)
          return vim.startswith(name, '.')
        end,
        -- this function defines what will never be shown, even when `show_hidden` is set
        is_always_hidden = function(name, bufnr)
          return false
        end,
        -- sort file names in a more intuitive order for humans. is less performant,
        -- so you can set to false if you prefer raw byte order. this will impact the
        -- order in which files are displayed in oil, but will not impact the order
        -- returned by things like require("oil").get_entry_on_line()
        natural_order = true,
        sort = {
          -- sort order can be "asc" or "desc"
          -- see :help oil-columns to see which columns are sortable
          { 'type', 'asc' },
          { 'name', 'asc' },
        },
      },

      -- extra arguments to pass to scp when moving/copying files over ssh
      extra_scp_args = {},

      -- experimental support for performing file operations with git
      git = {
        -- return true to automatically git add/mv/rm files
        add = function(path)
          return false
        end,
        mv = function(src_path, dest_path)
          return false
        end,
        rm = function(path)
          return false
        end,
      },

      -- configuration for the floating window in oil.open_float
      float = {
        -- padding around the floating window
        padding = 2,
        max_width = 0,
        max_height = 0,
        border = 'rounded',
        win_options = {
          winblend = 0,
        },
        -- preview_split: split direction: "auto", "left", "right", "above", "below".
        preview_split = 'auto',
        -- this is the config that will be passed to nvim_open_win.
        -- change values here to customize the layout
        override = function(conf)
          return conf
        end,
      },

      -- configuration for the actions floating preview window
      preview = {
        -- width dimensions can be integers or a float between 0 and 1 (e.g. 0.4 for 40%)
        -- min_width and max_width can be a single value or a list of mixed integer/float types.
        max_width = 0.9,
        -- min_width = {40, 0.4} means "at least 40 columns, or at least 40% of total"
        min_width = { 40, 0.4 },
        -- optionally define an integer/float for the exact width of the preview window
        width = nil,
        -- height dimensions can be integers or a float between 0 and 1 (e.g. 0.4 for 40%)
        -- min_height and max_height can be a single value or a list of mixed integer/float types.
        max_height = 0.9,
        min_height = { 5, 0.1 },
        -- optionally define an integer/float for the exact height of the preview window
        height = nil,
        border = 'rounded',
        win_options = {
          winblend = 0,
        },
        -- whether the preview window is automatically updated when the cursor is moved
        update_on_cursor_moved = true,
      },

      -- configuration for the floating progress window
      progress = {
        max_width = 0.9,
        min_width = { 40, 0.4 },
        width = nil,
        max_height = { 10, 0.9 },
        min_height = { 5, 0.1 },
        height = nil,
        border = 'rounded',
        minimized_border = 'none',
        win_options = {
          winblend = 0,
        },
      },

      -- configuration for the floating ssh window
      ssh = {
        border = 'rounded',
      },
    }
  end,
}
