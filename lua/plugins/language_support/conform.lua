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
        javascript = { 'prettierd' },
        typescript = { 'prettierd' },
        json = { 'prettierd' },
        yaml = { 'prettierd' },
        -- injected formats code blocks / cells with that language's formatter
        markdown = { 'prettierd', 'injected' },
        quarto = { 'prettierd', 'injected' },
        cpp = { 'clang_format' },
        c = { 'clang_format' },
        cuda = { 'clang_format' },
        hip = { 'clang_format' },
      },
      formatters = {
        -- prettierd keeps prettier running in the background (~70MB) , so a
        -- format takes ~10-20ms instead of ~150ms of node startup each save.
        -- it passes --option=value flags on to prettier (needs the = form).
        prettierd = {
          -- prettier picks its parser from the file extension and has none for
          -- .qmd , so it errored (silently) on every quarto save. quarto is
          -- markdown with a yaml header and {lang} code cells , which the
          -- markdown parser leaves alone.
          prepend_args = function(_, ctx)
            if vim.bo[ctx.buf].filetype == 'quarto' then
              return { '--tab-width=4', '--parser=markdown' }
            end
            return { '--tab-width=4' }
          end,
        },
        clang_format = clang_format_config,
        -- python cells use ruff instead of isort + black. those start a
        -- python process per tool per cell (~1.2s and timeouts on a 13 cell
        -- file) , ruff is one native binary that starts in a few ms. no import
        -- sorting in cells: it's cosmetic there and doubles the runs per cell
        injected = {
          options = {
            lang_to_formatters = {
              python = { 'ruff_format' },
            },
          },
        },
        -- wrap at 100 columns instead of ruff's default 88
        ruff_format = {
          prepend_args = { '--config', 'line-length=100' },
        },
      },
    }

    -- install formatters
    -- stylua is not installed through mason. install/bootstrap.sh curls the version pinned in
    -- install/versions.env into ~/.local/share/nvim/bootstrap/bin , a dir only nvim puts on its
    -- PATH , so that copy always wins inside nvim. mason's stylua also used to get picked up as
    -- an LSP , which caused issues. if you still have one , :MasonUninstall stylua
    local conform_tools = { 'prettierd', 'black', 'isort', 'ruff' }
    require('mason-tool-installer').setup {
      ensure_installed = conform_tools,
    }
  end,
}
