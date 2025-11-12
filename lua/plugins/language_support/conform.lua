-- note that core/format.lua controls whether LSP or conform will format the
-- file.
return {
  'stevearc/conform.nvim',
  dependencies = {
    'williamboman/mason.nvim',
    'WhoIsSethDaniel/mason-tool-installer.nvim',
  },
  event = { 'BufWritePre' },
  cmd = { 'ConformInfo' },

  config = function()
    require('conform').setup {
      notify_on_error = false,
      format_on_save = function()
        -- disabled .. we use format_range() instead
        return nil
      end,
      formatters_by_ft = {
        lua = { 'stylua' },
        python = { 'isort', 'black' },
        javascript = { 'prettier' },
        typescript = { 'prettier' },
        json = { 'prettier' },
        yaml = { 'prettier' },
        markdown = { 'prettier' },
        quarto = { 'prettier' },
      },
      formatters = {
        prettier = {
          prepend_args = { '--tab-width', '4' },
        },
      },
    }

    -- install formatters
    local conform_tools = { 'stylua', 'prettier', 'black', 'isort' }
    -- if you have issues with stylua being used as an LSP , :MasonUninstall stylua
    -- and just install it system wide , pacman -S stylua
    require('mason-tool-installer').setup {
      ensure_installed = conform_tools,
    }
  end,
}
