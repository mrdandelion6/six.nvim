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
    -- NOTE: if you ever want per project format settings for clang_format:
    --  1. in .localsettings.json , set custom_clang_format to true
    --  2. make a .clangd-format file in the project root with your settings
    --  3. for global settings , make a .clangd-format file in / or ~
    -- this is because command line args take precedence over any files
    local clang_format_config = {}

    -- check if custom .clang-format should be used
    if not (vim.g.local_settings and vim.g.local_settings.custom_clang_format) then
      -- use default inline style if custom_clang_format is not enabled
      clang_format_config = {
        prepend_args = {
          '--style={BasedOnStyle: LLVM, IndentWidth: 4, TabWidth: 4, UseTab: Never}',
        },
      }
    end

    -- else: leave empty so clang-format searches for .clang-format files
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
        cpp = { 'clang_format' },
        c = { 'clang_format' },
        cuda = { 'clang_format' },
        hip = { 'clang_format' },
      },
      formatters = {
        prettier = {
          prepend_args = { '--tab-width', '4' },
        },
        clang_format = clang_format_config,
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
