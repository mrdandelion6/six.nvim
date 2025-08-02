local platform = require 'core.platform'

return {
  'lervag/vimtex',
  lazy = false,
  init = function()
    -- vimtex configuration
    if platform.is_linux() then
      vim.g.vimtex_view_method = 'zathura'
    elseif platform.is_windows() or platform.is_wsl() then
      vim.g.vimtex_view_method = 'general'
      vim.g.vimtex_view_general_viewer = 'texworks'
      vim.g.vimtex_view_general_options = '@pdf'
    end

    -- compiler settings
    vim.g.vimtex_compiler_method = 'latexmk'
    vim.g.vimtex_compiler_latexmk = {
      build_dir = '',
      aux_dir = '.tex_info',
      out_dir = '',
      callback = 1,
      continuous = 1,
      executable = 'latexmk',
      options = {
        '-verbose',
        '-file-line-error',
        '-synctex=1',
        '-interaction=nonstopmode',
      },
    }

    -- set default compiler (can be overridden per project)
    vim.g.vimtex_compiler_latexmk_engines = {
      _ = '-pdf',
      pdflatex = '-pdf',
      xelatex = '-xelatex',
      lualatex = '-lualatex',
    }

    -- disable default keymaps
    vim.g.vimtex_mappings_enabled = 0
  end,

  config = function()
    vim.api.nvim_create_autocmd('FileType', {
      pattern = 'tex',
      callback = function()
        -- buffer-local settings
        vim.opt_local.wrap = true
        vim.opt_local.linebreak = true
        vim.opt_local.spell = true
        vim.opt_local.spelllang = 'en_us'

        -- key mappings for latex
        local opts = { buffer = true, silent = true }
        vim.keymap.set('n', '<leader>ll', '<cmd>VimtexCompile<cr>', opts)
        vim.keymap.set('n', '<leader>lv', '<cmd>VimtexView<cr>', opts)
        vim.keymap.set('n', '<leader>lc', '<cmd>VimtexClean<cr>', opts)
        vim.keymap.set('n', '<leader>ls', '<cmd>VimtexStop<cr>', opts)
        vim.keymap.set('n', '<leader>lt', '<cmd>VimtexTocToggle<cr>', opts)
        vim.keymap.set('n', '<leader>lg', '<cmd>VimtexStatus<cr>', opts)
      end,
    })
  end,
}
