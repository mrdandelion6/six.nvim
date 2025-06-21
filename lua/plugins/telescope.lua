return { -- fuzzy finder (files, lsp, etc)
  'nvim-telescope/telescope.nvim',
  event = 'VimEnter',
  branch = '0.1.x',
  dependencies = {
    'nvim-lua/plenary.nvim',
    { -- if encountering errors, see telescope-fzf-native readme for installation instructions
      'nvim-telescope/telescope-fzf-native.nvim',

      -- `build` is used to run some command when the plugin is installed/updated.
      -- this is only run then, not every time neovim starts up.
      build = 'make',

      -- `cond` is a condition used to determine whether this plugin should be
      -- installed and loaded.
      cond = function()
        return vim.fn.executable 'make' == 1
      end,
    },
    { 'nvim-telescope/telescope-ui-select.nvim' },

    -- useful for getting pretty icons, but requires a nerd font.
    { 'nvim-tree/nvim-web-devicons',            enabled = vim.g.have_nerd_font },
  },

  config = function()
    -- telescope is a fuzzy finder that comes with a lot of different things.
    --  :Telescope help_tags
    -- [[ configure telescope ]]
    -- see `:help telescope` and `:help telescope.setup()`
    require('telescope').setup {
      -- you can put your default mappings / updates / etc. in here
      --  all the info you're looking for is in `:help telescope.setup()`
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

    -- enable telescope extensions if they are installed
    pcall(require('telescope').load_extension, 'fzf')
    pcall(require('telescope').load_extension, 'ui-select')

    -- see `:help telescope.builtin`
    local builtin = require 'telescope.builtin'

    vim.api.nvim_set_hl(0, 'TelescopeBorder', { fg = '#e4abd4' })

    local function get_opts()
      -- attempts to use fdfind or fd if former not available.
      -- if neither available, defaults to vim's built in file finding functions.
      local opts = {
        hidden = true,
      }
      -- ripgrep is the best one for ignoring binaries etc.
      if vim.fn.executable 'rg' == 1 then
        opts.find_command = {
          'rg',
          '-l',
          '.*',
          '--follow',
          '--hidden',
          '--no-ignore-vcs',
          '--glob',
          '!.git',
          '--glob',
          '!lib',
          '--glob',
          '!node_modules',
          '--glob',
          '!target',
          '--glob',
          '!dist',
          '--glob',
          '!.*/',
          '--glob',
          '!build',
        }
      elseif vim.fn.executable 'fdfind' == 1 then
        opts.find_command = { -- ignore .git/, node_modules/, and other directories we typically wouldn't search.
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
          '--exclude',
          '.*/',
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
          '--exclude',
          '.*/',
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
      return opts
    end

    --
    vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = '[F]ind [H]elp' })

    -- find vim keymaps
    vim.keymap.set('n', '<leader>fk', builtin.keymaps, { desc = '[F]ind [K]eymaps' })

    -- find different telescope pickers. for example, `find_files` picker which is '<leader>ff'.
    vim.keymap.set('n', '<leader>fs', builtin.builtin, { desc = '[F]ind [S]pecific finder' })

    -- find the word currently under the cursor in your buffer in same picker as <leader>fg but pre-populated.
    vim.keymap.set('n', '<leader>fw', builtin.grep_string, { desc = '[S]earch [W]ord under cursor' })

    -- search text inside files within pwd
    vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = '[F]ind by [G]rep' })

    -- search diagnostics and warnings within current buffer
    vim.keymap.set('n', '<leader>fd', builtin.diagnostics, { desc = '[F]ind [D]iagnostics' })

    -- repeat last search
    vim.keymap.set('n', '<leader>fa', builtin.resume, { desc = '[F]ind [A]gain' })

    -- search recently opened files
    vim.keymap.set('n', '<leader>fr', builtin.oldfiles, { desc = '[F]ind [R]ecently viewed' })

    -- search for existing buffers
    vim.keymap.set('n', '<leader><leader>', builtin.buffers, { desc = '[ ] Find existing buffers' })

    -- shortcut for searching your neovim configuration files
    vim.keymap.set('n', '<leader>fe', function()
      local opts = get_opts()
      opts.cwd = vim.fn.stdpath 'config'
      builtin.find_files(opts)
    end, { desc = '[F]ind N[e]ovim files' })

    -- shortcut for searching files in my Learn_to_Code repository
    vim.keymap.set('n', '<leader>fn', function()
      if vim.g.local_settings then
        if vim.g.local_settings.notes_path then
          local opts = get_opts()
          opts.cwd = vim.g.local_settings.notes_path
          print('notes path is: ' .. vim.g.local_settings.notes_path)
          builtin.find_files(opts)
        else
          print 'ERROR (telescope.lua): vim.g.local_settings.notes_path is nil'
        end
      else
        print 'ERROR (telescope.lua): vim.g.local_settings is nil'
      end
    end, { desc = '[F]ind [N]otes' })

    -- fuzzy search for files in pwd.
    vim.keymap.set('n', '<leader>ff', function()
      builtin.find_files(get_opts())
    end, { desc = '[F]ind [F]iles' })

    -- slightly advanced example of overriding default behavior and theme
    vim.keymap.set('n', '<leader>/', function()
      -- you can pass additional configuration to telescope to change the theme, layout, etc.
      builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
        previewer = false,
      })
    end, { desc = '[/] Fuzzily search in current buffer' })

    -- it's also possible to pass additional configuration options.
    --  see `:help telescope.builtin.live_grep()` for information about particular keys
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
