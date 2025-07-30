--[[

  NOTE: HELP:

    :help
      This will open up a help window with some basic information
      about reading, navigating and searching the builtin help documentation.

    "<space>sh"
      to [s]earch the [h]elp documentation,
      which is very useful when you're not exactly sure of what you're looking for.

    "<space>sk"
      to [s]earch for the set [k]eymaps easily.

    crash demo of lua
      https://learnxinyminutes.com/docs/lua/

    :help lua-guide
      reference for how neovim integrates lua after you understand some basic lua.

    learn lua in depth and how to use it in neovim
      https://github.com/mrdandelion6/learn-to-code/blob/main/languages/lua/notes.lua

    kickstart.nvim setup guide
      https://github.com/mrdandelion6/Learn-to-Code/blob/main/topics/using-vim/neovim.md

    intro to vim and vim motions guide
      https://github.com/mrdandelion6/Learn-to-Code/blob/main/topics/using-vim/vim.md

    :checkhealth
      if you experience any errors while trying to install kickstart, run `:checkhealth` for more info.

--]]

vim.g.mapleader = ' '
vim.g.maplocalleader = ' '
vim.g.have_nerd_font = true

require('core.lazy').boostrap()

require 'core.platform'
require 'core.options'
require 'core.keymaps'
require 'core.autocmds'
require 'core.cmds'

require('lazy').setup({
  { import = 'plugins' },
  { import = 'local' },
}, require('core.ui').lazy)

-- the line beneath this is called `modeline`. see `:help modeline`
-- vim: ts=2 sts=2 sw=2 et
