print 'yo'
return {
  {
    'anuvyklack/hydra.nvim',
    dependencies = 'anuvyklack/keymap-layer.nvim',
  },
  {
    'GCBallesteros/jupytext.nvim',
    event = { 'BufReadPre *.ipynb', 'BufNewFile *.ipynb' }, -- Change from ft to event
    dependencies = {
      'nvim-lua/plenary.nvim',
    },
    lazy = false,
    config = function()
      vim.notify('Configuring jupytext...', vim.log.levels.INFO) -- Added log level
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
      vim.api.nvim_create_user_command('JupytextToMd', function()
        require('jupytext').to_fmt 'md'
      end, {})
      vim.notify('Jupytext configuration complete', vim.log.levels.INFO)
    end,
  },
  { 'jmbuhr/otter.nvim', ft = { 'markdown', 'quarto', 'norg' } },
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
          },
          default_method = 'molten',
        },
      }

      vim.keymap.set('n', '<localleader>qp', quarto.quartoPreview, { desc = 'Preview the Quarto document', silent = true, noremap = true })
      -- to create a cell in insert mode, I have the ` snippet
      vim.keymap.set('n', '<localleader>cc', 'i`<c-j>', { desc = 'Create a new code cell', silent = true })
      vim.keymap.set('n', '<localleader>cs', 'i```\r\r```{}<left>', { desc = 'Split code cell', silent = true, noremap = true })
    end,
  },
}
