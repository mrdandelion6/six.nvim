return {
  {
    'anuvyklack/hydra.nvim',
    dependencies = 'anuvyklack/keymap-layer.nvim',
  },
  {
    'GCBallesteros/jupytext.nvim',
    event = { 'BufReadPre *.ipynb', 'BufNewFile *.ipynb' },
    dependencies = {
      'nvim-lua/plenary.nvim',
    },
    lazy = false,
    config = function()
      require('jupytext').setup {
        style = 'markdown',
        output_extension = 'md',
        force_ft = 'markdown',
        custom_language_formatting = {
          python = {
            extension = 'md',
            style = 'markdown',
            force_ft = 'markdown',
          },
        },
      }

      -- async save. jupytext.nvim's own save writes the .md then runs
      -- `jupytext --update --to ipynb` with vim.fn.system , freezing nvim for
      -- ~4s (mostly jupytext's python imports). here we only wait for the .md
      -- write and convert to .ipynb in the background. saving again while a
      -- conversion runs queues one more , so the .ipynb ends up matching the
      -- last save.
      local converting = {} -- ipynb path -> true while jupytext runs
      local pending = {} -- ipynb path -> true if saved again meanwhile

      local function convert(ipynb, md)
        converting[ipynb] = true
        pending[ipynb] = nil
        local ok, err = pcall(
          vim.system,
          { 'jupytext', md, '--update', '--to', 'ipynb', '--output', ipynb },
          { text = true },
          vim.schedule_wrap(function(res)
            converting[ipynb] = nil
            if res.code ~= 0 then
              vim.notify(
                'jupytext: could not update ' .. ipynb .. '\n' .. (res.stderr or ''),
                vim.log.levels.ERROR
              )
            end
            if pending[ipynb] then
              convert(ipynb, md)
            end
          end)
        )
        -- jupytext missing from PATH (ex. nvim started outside the neovim venv)
        if not ok then
          converting[ipynb] = nil
          vim.notify('jupytext: ' .. tostring(err), vim.log.levels.ERROR)
        end
      end

      local function write(ev)
        local ipynb = vim.fn.resolve(vim.fn.fnamemodify(ev.match, ':p'))
        local md = vim.fn.fnamemodify(ipynb, ':r') .. '.md'
        vim.cmd.write { md, bang = true }
        vim.bo[ev.buf].modified = false
        if converting[ipynb] then
          pending[ipynb] = true
        else
          convert(ipynb, md)
        end
        local post = ev.event == 'FileWriteCmd' and 'FileWritePost' or 'BufWritePost'
        vim.api.nvim_exec_autocmds(post, { pattern = ev.match })
      end

      -- jupytext.nvim adds its buffer-local write autocmd while reading the
      -- notebook. this runs right after (same event , defined later) and
      -- swaps it for the async one.
      vim.api.nvim_create_autocmd('BufReadCmd', {
        pattern = '*.ipynb',
        group = vim.api.nvim_create_augroup('jupytext-async-write', { clear = true }),
        callback = function(ev)
          for _, au in
            ipairs(vim.api.nvim_get_autocmds {
              group = 'jupytext-nvim',
              event = { 'BufWriteCmd', 'FileWriteCmd' },
              buffer = ev.buf,
            })
          do
            vim.api.nvim_del_autocmd(au.id)
          end
          vim.api.nvim_create_autocmd({ 'BufWriteCmd', 'FileWriteCmd' }, {
            buffer = ev.buf,
            group = 'jupytext-async-write',
            callback = write,
          })
        end,
      })
    end,
  },
  {
    'jmbuhr/otter.nvim',
    ft = { 'markdown', 'quarto', 'norg' },
    opts = {
      lsp = {
        -- default is BufWritePost only , so errors in code cells only showed
        -- up after saving. also update when leaving insert mode or changing
        -- text in normal mode , like diagnostics in a normal .py file
        diagnostic_update_events = { 'BufWritePost', 'InsertLeave', 'TextChanged' },
      },
    },
  },
  {
    'quarto-dev/quarto-nvim',
    dependencies = {
      'nvim-lspconfig',
      'hydra.nvim',
      'otter.nvim',
    },
    ft = { 'quarto', 'markdown', 'norg' },
    config = function()
      local quarto = require 'quarto'
      quarto.setup {
        lspFeatures = {
          languages = { 'python', 'rust', 'lua' },
          chunks = 'all', -- 'curly' or 'all'
          diagnostics = {
            enabled = true,
            triggers = { 'BufWritePost' },
          },
          completion = {
            enabled = true,
          },
        },
        keymap = {
          hover = 'H',
          definition = 'gd',
          rename = '<leader>rn',
          references = 'gr',
          format = '<leader>gf',
        },
        codeRunner = {
          enabled = true,
          ft_runners = {
            bash = 'slime',
            python = 'molten',
            markdown = 'molten',
          },
          default_method = 'molten',
        },
      }

      vim.api.nvim_create_autocmd('FileType', {
        pattern = { 'markdown', 'quarto' },
        callback = function()
          require('quarto').activate()
        end,
      })
    end,
  },
}
