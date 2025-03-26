return { -- Fuzzy Finder (files, lsp, etc)
  'nvim-telescope/telescope.nvim',
  event = 'VimEnter',
  branch = '0.1.x',
  dependencies = {
    'nvim-lua/plenary.nvim',
    { -- If encountering errors, see telescope-fzf-native README for installation instructions
      'nvim-telescope/telescope-fzf-native.nvim',

      -- `build` is used to run some command when the plugin is installed/updated.
      -- This is only run then, not every time Neovim starts up.
      build = 'make',

      -- `cond` is a condition used to determine whether this plugin should be
      -- installed and loaded.
      cond = function()
        return vim.fn.executable 'make' == 1
      end,
    },
    { 'nvim-telescope/telescope-ui-select.nvim' },

    -- Useful for getting pretty icons, but requires a Nerd Font.
    { 'nvim-tree/nvim-web-devicons', enabled = vim.g.have_nerd_font },
  },

  config = function()
    -- Telescope is a fuzzy finder that comes with a lot of different things.
    --  :Telescope help_tags

    -- [[ Configure Telescope ]]
    -- See `:help telescope` and `:help telescope.setup()`
    require('telescope').setup {
      -- You can put your default mappings / updates / etc. in here
      --  All the info you're looking for is in `:help telescope.setup()`
      --
      -- defaults = {
      --   mappings = {
      --     i = { ['<c-enter>'] = 'to_fuzzy_refine' },
      --   },
      -- },
      -- pickers = {}
      extensions = {
        ['ui-select'] = {
          require('telescope.themes').get_dropdown(),
        },
      },
    }

    -- Enable Telescope extensions if they are installed
    pcall(require('telescope').load_extension, 'fzf')
    pcall(require('telescope').load_extension, 'ui-select')

    -- See `:help telescope.builtin`
    local builtin = require 'telescope.builtin'

    vim.api.nvim_set_hl(0, 'TelescopeBorder', { fg = '#e4abd4' })

    --
    vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = '[F]ind [H]elp' })

    -- Find vim keymaps
    vim.keymap.set('n', '<leader>fk', builtin.keymaps, { desc = '[F]ind [K]eymaps' })

    -- Find different telescope pickers. For example, `find_files` picker which is '<leader>ff'.
    vim.keymap.set('n', '<leader>fs', builtin.builtin, { desc = '[F]ind [S]pecific finder' })

    -- Find the word currently under the cursor in your buffer in same picker as <leader>fg but pre-populated.
    vim.keymap.set('n', '<leader>fw', builtin.grep_string, { desc = '[S]earch [W]ord under cursor' })

    -- Search text inside files within PWD
    vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = '[F]ind by [G]rep' })

    -- Search diagnostics and warnings within current buffer
    vim.keymap.set('n', '<leader>fd', builtin.diagnostics, { desc = '[F]ind [D]iagnostics' })

    -- Repeat last search
    vim.keymap.set('n', '<leader>fa', builtin.resume, { desc = '[F]ind [A]gain' })

    -- Search recently opened files
    vim.keymap.set('n', '<leader>fr', builtin.oldfiles, { desc = '[F]ind [R]ecently viewed' })

    -- Search for existing buffers
    vim.keymap.set('n', '<leader><leader>', builtin.buffers, { desc = '[ ] Find existing buffers' })

    -- Shortcut for searching your Neovim configuration files
    vim.keymap.set('n', '<leader>fe', function()
      builtin.find_files { cwd = vim.fn.stdpath 'config' }
    end, { desc = '[F]ind N[e]ovim files' })

    vim.keymap.set('n', '<leader>ff', function()
      -- Fuzzy search for files in PWD.
      -- Attempts to use fdfind or fd if former not available.
      -- If neither available, defaults to Vim's built in file finding functions.
      local opts = {
        hidden = true,
      }
      if vim.fn.executable 'rg' == 1 then
        opts.find_command = {
          'rg',
          '--files',
          '--hidden',
          '--no-ignore-vcs',
          '--no-binary',
          '--glob',
          '!.git/*',
          '--glob',
          '!node_modules/*',
          '--glob',
          '!target/*',
          '--glob',
          '!dist/*',
          '--glob',
          '!.build/*',
        }
        vim.notify 'Using ripgrep'
      elseif vim.fn.executable 'fdfind' == 1 then
        opts.find_command = { -- Ignore .git/, node_modules/, and other directories we typically wouldn't search.
          'fdfind',
          '--type',
          'f',
          '--hidden',
          '--no-ignore-vcs',
          '--exclude',
          '.git',
          '--exclude',
          'node_modules',
          '--exclude',
          'target',
          '--exclude',
          'dist',
        }
        vim.notify('Using fd-find', vim.log.levels.INFO)
      elseif vim.fn.executable 'fd' == 1 then
        opts.find_command = {
          'fd',
          '--type',
          'f',
          '--exclude',
          '.git',
          '--exclude',
          'node_modules',
          '--exclude',
          'target',
          '--exclude',
          'dist',
        }
        vim.notify('Using fd', vim.log.levels.INFO)
      else
        opts.file_ignore_patterns = {
          '^.git/',
          'node_modules/',
          'target/',
          'dist/',
        }
        vim.notify('Using default finder', vim.log.levels.INFO)
      end
      builtin.find_files(opts)
    end, { desc = '[F]ind [F]iles' })

    -- Slightly advanced example of overriding default behavior and theme
    vim.keymap.set('n', '<leader>/', function()
      -- You can pass additional configuration to Telescope to change the theme, layout, etc.
      builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
        previewer = false,
      })
    end, { desc = '[/] Fuzzily search in current buffer' })

    -- It's also possible to pass additional configuration options.
    --  See `:help telescope.builtin.live_grep()` for information about particular keys
    vim.keymap.set('n', '<leader>f/', function()
      builtin.live_grep {
        grep_open_files = true,
        prompt_title = 'Live Grep in Open Files',
      }
    end, { desc = '[F]ind [/] in Open Files' })

    vim.api.nvim_create_user_command('UpdateTelescopeMaps', function()
      local new_maps = vim.g.telescope_maps or {}
      require('telescope').setup {
        defaults = {
          mappings = new_maps,
        },
      }
    end, {})

    vim.api.nvim_create_autocmd('User', {
      pattern = 'TelescopeMapsChanged',
      callback = function()
        vim.cmd 'UpdateTelescopeMaps'
      end,
    })

    vim.cmd 'UpdateTelescopeMaps' -- run once on load
  end,
}
