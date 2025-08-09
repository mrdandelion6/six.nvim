return {
  -- gitsigns left of line numbers to indicate file modification
  {
    'lewis6991/gitsigns.nvim',
    opts = {
      signs = {
        add = { text = '+' },
        change = { text = '~' },
        delete = { text = '_' },
        topdelete = { text = '‾' },
        changedelete = { text = '~' },
      },
      on_attach = function(bufnr)
        local gitsigns = require 'gitsigns'

        local function map(mode, l, r, opts)
          opts = opts or {}
          opts.buffer = bufnr
          vim.keymap.set(mode, l, r, opts)
        end

        -- navigation
        map('n', ']c', function()
          if vim.wo.diff then
            vim.cmd.normal { ']c', bang = true }
          else
            gitsigns.nav_hunk 'next'
          end
        end, { desc = 'Jump to next git [c]hange' })
        map('n', '[c', function()
          if vim.wo.diff then
            vim.cmd.normal { '[c', bang = true }
          else
            gitsigns.nav_hunk 'prev'
          end
        end, { desc = 'Jump to previous git [c]hange' })

        -- staging
        map('n', '<leader>gs', gitsigns.stage_hunk, { desc = 'git [s]tage hunk' })
        map('n', '<leader>gS', gitsigns.stage_buffer, { desc = 'git [S]tage buffer' })

        -- hard resetting stage
        map('n', '<leader>gr', gitsigns.reset_hunk, { desc = 'git [r]eset hunk' })
        map('n', '<leader>gR', gitsigns.reset_buffer, { desc = 'git [R]eset buffer' })

        -- diff
        map('n', '<leader>gp', gitsigns.preview_hunk, { desc = 'git [p]review hunk' })
        map('n', '<leader>gd', gitsigns.diffthis, { desc = 'git [d]iff against index' })
        map('n', '<leader>gD', function()
          gitsigns.diffthis '@'
        end, { desc = 'git [D]iff against last commit' })

        -- blame
        map('n', '<leader>gb', gitsigns.blame_line, { desc = 'git [b]lame line' })
        map('n', '<leader>gB', gitsigns.toggle_current_line_blame, { desc = '[T]oggle git show [b]lame line' })
      end,
    },
  },

  -- vim fugitive for repo level git control
  {
    'tpope/vim-fugitive',
    cmd = { 'G', 'Git', 'Gdiffsplit', 'Gread', 'Gwrite', 'Ggrep', 'GMove', 'GDelete', 'GBrowse' },
    keys = {
      { '<leader>gg', '<cmd>G<cr>', desc = 'Fugitive Status' },
    },
  },
}
