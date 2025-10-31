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
