return {
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
    { 'nvim-tree/nvim-web-devicons', enabled = vim.g.have_nerd_font },
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

    local colors = require 'core.colors'

    -- enable telescope extensions if they are installed
    pcall(require('telescope').load_extension, 'fzf')
    pcall(require('telescope').load_extension, 'ui-select')

    -- see `:help telescope.builtin`
    local builtin = require 'telescope.builtin'
    vim.api.nvim_set_hl(0, 'TelescopeBorder', { fg = colors.lighter_pink })

    local function get_opts(path)
      -- return a table of options for telescope fuzzy searching. we need this
      -- to determine what finder backend we are using and the proper commands
      -- for them.

      -- attempts to use the following finders in order:
      --  1. ripgrep
      --  2. fdfind
      --  3. fd
      --  4. vim's built in file funding functions

      -- HACK: later on , add an efficient way to gauge how many children files
      -- there are in the path being searched. for now we just assume that we
      -- are in a big dir if we are in some hardcoded paths
      local home = vim.fn.expand '~'
      local big_dir_paths = {
        ['/'] = true,
        [home] = true,
        ['/usr'] = true,
        ['/opt'] = true,
        ['/var'] = true,
      }

      local big_dir = path and big_dir_paths[path] or false

      if big_dir then
        vim.notify('Searching large directory: ' .. path .. ' (binary filtering disabled)', vim.log.levels.INFO)
      end

      local opts = {
        hidden = true,
      }

      local platform = require 'core.platform'
      local utils = require 'core.utils'

      -- NOTE: rg is great for ignoring binaries , but it also ignores empty
      -- files. to include empty files we combine rg with find.
      if vim.fn.executable 'rg' == 1 then
        local common_excludes = {
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
        }

        local cache_excludes = {
          '--glob',
          '!.cache/',
          '--glob',
          '!.npm/',
          '--glob',
          '!.cargo/',
        }

        local linux_system_excludes = {
          '--glob',
          '!.rustup/',
          '--glob',
          '!.local/share/',
          '--glob',
          '!/tmp/**',
          '--glob',
          '!/snap/**',
          '--glob',
          '!/proc/**',
          '--glob',
          '!/sys/**',
          '--glob',
          '!/boot/**',
          '--glob',
          '!/dev/**',
        }

        local windows_system_excludes = {
          '--glob',
          '!AppData/Local/',
          '--glob',
          '!AppData/Roaming/npm-cache/',
        }

        -- helper to convert exclude table to string
        local function excludes_to_string(exclude_tables)
          local parts = {}
          for _, tbl in ipairs(exclude_tables) do
            for i = 1, #tbl, 2 do
              -- skip the '--glob' and just get the pattern
              table.insert(parts, tbl[i + 1])
            end
          end
          return table.concat(
            vim.tbl_map(function(pattern)
              return '--glob "' .. pattern .. '"'
            end, parts),
            ' '
          )
        end

        local base_rg_args = {
          'rg',
          '--files',
          '--follow',
          '--hidden',
          '--no-ignore-vcs',
          '--max-filesize',
          '10M',
        }

        if platform.is_windows() then
          if big_dir then
            opts.find_command = utils.union_tables(base_rg_args, common_excludes, cache_excludes, windows_system_excludes)
          else
            local exclude_str = excludes_to_string { common_excludes, cache_excludes }
            opts.find_command = {
              'powershell',
              '-NoProfile',
              '-Command',
              'rg -l "" --follow --hidden --no-ignore-vcs --max-filesize 10M '
                .. exclude_str
                .. ' 2>$null; '
                .. 'Get-ChildItem -Recurse -File | Where-Object {$_.Length -eq 0} | Select-Object -ExpandProperty FullName',
            }
          end
        else -- linux
          if big_dir then
            opts.find_command = utils.union_tables(base_rg_args, common_excludes, cache_excludes, linux_system_excludes)
          else
            local exclude_str = excludes_to_string { common_excludes, cache_excludes }
            opts.find_command = {
              'sh',
              '-c',
              'rg -l "" --follow --hidden --no-ignore-vcs --max-filesize 10M ' .. exclude_str .. ' 2>/dev/null; ' .. 'find . -type f -empty',
            }
          end
        end
      else
        vim.notify 'ripgrep missing. Telescope.nvim uses ripgrep on your system to find files.'
      end
      return opts
    end

    --[[
    ****************************************************************************
                                        COMMANDS
    ****************************************************************************
    --]]

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

    --[[
    ****************************************************************************
                                        KEYMAPS
    ****************************************************************************
    --]]
    -- TODO:
    -- 1. searching for files in a specific path
    -- 2. searching for files in the repo of the current buffer

    -- help
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
      opts.prompt_title = 'Find Files in Neovim Config'
      builtin.find_files(opts)
    end, { desc = '[F]ind N[e]ovim files' })

    -- fuzzy search in my learn_to_code repository
    vim.keymap.set('n', '<leader>fn', function()
      if vim.g.local_settings then
        if vim.g.local_settings.notes_path then
          local opts = get_opts()
          opts.cwd = vim.g.local_settings.notes_path
          opts.prompt_title = 'Find Code Notes'
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
      builtin.find_files(get_opts(vim.fn.getcwd()))
    end, { desc = '[F]ind [F]iles' })

    vim.keymap.set('n', '<leader>fp', function()
      -- fuzzy seach for files in some specified path using zoxide if available.
      -- if the path provided is "." , then fuzzy find files in the pwd of the
      -- current buffer. if nothing is provided (enter was pressed without)
      -- any path , fuzzy find files in the entire system (slow).

      -- create a floating window for input
      local buf = vim.api.nvim_create_buf(false, true) -- no file, scratch buffer
      local width = 60
      local height = 1
      local row = math.floor((vim.o.lines - height) / 2)
      local col = math.floor((vim.o.columns - width) / 2)

      local win = vim.api.nvim_open_win(buf, true, {
        relative = 'editor',
        width = width,
        height = height,
        row = row,
        col = col,
        style = 'minimal',
        border = 'rounded',
        title = ' Search Path ',
        title_pos = 'center',
      })

      vim.api.nvim_win_set_option(win, 'winhl', 'FloatBorder:TelescopeBorder')

      -- set up the buffer
      vim.api.nvim_buf_set_option(buf, 'buftype', 'prompt')
      vim.fn.prompt_setprompt(buf, '> ')

      -- mark buffer as not modified
      vim.api.nvim_buf_set_option(buf, 'modified', false)

      -- auto delete buffer when it is hidden
      vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')

      -- start insert mode
      vim.cmd 'startinsert'

      -- handle enter key
      vim.keymap.set('i', '<CR>', function()
        local utils = require 'core.utils'
        local input = vim.api.nvim_buf_get_lines(buf, 0, -1, false)[1]
        input = input:gsub('^> ', '') -- remove prompt prefix

        -- close the floating window
        vim.api.nvim_win_close(win, true)

        local search_path

        if input == '' or input == '/' then
          search_path = '/'
        elseif input == '.' then
          -- first try to get the git root of the buffer's file if it exists
          search_path = utils.get_git_root(true)
          -- if the file doesn't have a git root then just get its parent dir
          if search_path == '' then
            local current_file = vim.fn.expand '%:p'
            search_path = vim.fn.fnamemodify(current_file, ':h')
          end
        else
          -- try zoxide
          local handle = io.popen('zoxide query ' .. input .. ' 2>/dev/null')
          if handle then
            local result = handle:read '*a'
            handle:close()
            search_path = result:gsub('%s+$', '')

            if search_path == '' then
              search_path = vim.fn.expand(input)
            end
          else
            search_path = vim.fn.expand(input)
          end
        end

        if vim.fn.isdirectory(search_path) == 0 then
          vim.notify('Path does not exist: ' .. search_path, vim.log.levels.ERROR)
          return
        end

        local opts = get_opts(search_path)
        opts.cwd = search_path
        opts.prompt_title = 'Find Files in: ' .. search_path
        require('telescope.builtin').find_files(opts)
      end, { buffer = buf })

      -- handle escape key
      vim.keymap.set('i', '<Esc>', function()
        vim.api.nvim_win_close(win, true)
      end, { buffer = buf })
    end, { desc = '[F]ind files in specific [P]ath (with zoxide)' })

    -- fuzzy find in current buffer.. like regular / but with a menu
    vim.keymap.set('n', '<leader>/', function()
      -- you can pass additional configuration to telescope to change the theme, layout, etc.
      builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
        previewer = false,
      })
    end, { desc = '[/] Fuzzily search in current buffer' })

    --  fuzzy grep open files
    vim.keymap.set('n', '<leader>f/', function()
      builtin.live_grep {
        grep_open_files = true,
        prompt_title = 'Live Grep in Open Files',
      }
    end, { desc = '[F]ind [/] in Open Files' })

    vim.cmd 'UpdateTelescopeMaps' -- run once on load
  end,
}
