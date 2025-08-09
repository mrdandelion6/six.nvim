return { -- highlight, edit, and navigate code
  'nvim-treesitter/nvim-treesitter',
  build = ':TSUpdate',
  main = 'nvim-treesitter.configs', -- sets main module to use for opts
  opts = {
    ensure_installed = { 'bash', 'c', 'diff', 'html', 'lua', 'luadoc', 'markdown', 'markdown_inline', 'query', 'vim', 'vimdoc' },
    -- autoinstall languages that are not installed
    auto_install = true,
    highlight = {
      enable = true,
      -- some languages depend on vim's regex highlighting system (such as ruby) for indent rules.
      --  if you are experiencing weird indenting issues, add the language to
      --  the list of additional_vim_regex_highlighting and disabled languages for indent.
      additional_vim_regex_highlighting = { 'ruby' },
    },
    indent = { enable = true, disable = { 'ruby' } },
  },
  -- there are additional nvim-treesitter modules that you can use to interact
  -- with nvim-treesitter. you should go explore a few and see what interests you:
  --
  --    - incremental selection: included, see `:help nvim-treesitter-incremental-selection-mod`
  --    - show your current context: https://github.com/nvim-treesitter/nvim-treesitter-context
  --    - treesitter + textobjects: https://github.com/nvim-treesitter/nvim-treesitter-textobjects
}
