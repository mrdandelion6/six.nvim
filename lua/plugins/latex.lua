local platform = require 'core.platform'

return {
  'lervag/vimtex',
  cmd = { 'VimtexCompile', 'VimtexView', 'VimtexClean' },
  ft = 'tex',
  init = function()
    -- vimtex configuration
    if platform.is_linux() then
      vim.g.vimtex_view_method = 'zathura'
    elseif platform.is_windows() or platform.is_wsl() then
      vim.g.vimtex_view_method = 'general'
      vim.g.vimtex_view_general_viewer = 'SumatraPDF'
      vim.g.vimtex_view_general_options = '-reuse-instance'
    end

    -- compiler settings
    vim.g.vimtex_compiler_method = 'latexmk'
    vim.g.vimtex_compiler_latexmk = {
      build_dir = '',
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
  end,
}
