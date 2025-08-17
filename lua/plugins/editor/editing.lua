return {
  'tpope/vim-sleuth', -- detect tabstop and shiftwidth automatically

  {
    'numToStr/Comment.nvim', -- allows "gc" operator for quick commenting
    opts = {},
    lazy = false,
  },

  -- highlight todo, notes, etc in comments
  { 'folke/todo-comments.nvim', event = 'VimEnter', dependencies = { 'nvim-lua/plenary.nvim' }, opts = { signs = false } },
}
