return { -- for persisting neovim sessions.
  'rmagatti/auto-session',
  priority = 999, -- this is needed.
  -- without the above , if statusline.lua loads first , terminal title won't
  -- update.
  config = function()
    local auto_session = require 'auto-session'

    auto_session.setup {
      log_level = 'error',
      auto_session_enable_last_session = false,
      auto_session_root_dir = vim.fn.stdpath 'data' .. '/sessions/',
      auto_session_enabled = true,
      auto_save_enabled = false,
      auto_restore_enabled = true,
      auto_session_suppress_dirs = nil,
      auto_session_use_git_branch = nil,
      session_lens = {
        folder_name = false,
        path_display = { 'truncate' },
        telescope = {
          mappings = {
            delete_session = {
              ['<C-d>'] = 'delete_session',
            },
          },
        },
      },
    }

    -- automatically save the session when exiting nvim if session exists.
    vim.api.nvim_create_autocmd('VimLeavePre', {
      callback = function()
        if auto_session.session_exists_for_cwd() then
          auto_session.SaveSession()
        end
      end,
    })

    -- if opened cwd isn't an existing session, spawn a terminal on the right
    vim.api.nvim_create_autocmd('VimEnter', {
      callback = function()
        local platform = require 'core.platform'
        if not auto_session.session_exists_for_cwd() then
          -- check if we started with a directory argument
          local args = vim.fn.argv()
          local started_with_directory = #args == 1 and vim.fn.isdirectory(args[1]) == 1

          vim.cmd 'vsplit | wincmd l'
          local ratio = 0.45
          if platform.is_windows() then
            -- terminals spawned inside windows for nvim cant shrink fastfetch
            -- output for some reason , so need more space.
            ratio = 0.52
          end
          local width = math.floor(vim.o.columns * ratio)
          vim.cmd('vertical resize ' .. width .. ' | terminal')
          vim.cmd 'wincmd h'

          -- if we started with a directory, open it with oil in the left pane
          if started_with_directory then
            require('oil').open(args[1])
          end
        end
      end,
    })

    -- added this because no message was displaying automatically.
    local function delete_session_with_notification()
      if auto_session.session_exists_for_cwd() then
        auto_session.DeleteSession()
        vim.notify('Deleted session: ' .. vim.fn.getcwd(), vim.log.levels.INFO)
      else
        vim.notify('Session does not exist: ' .. vim.fn.getcwd(), vim.log.levels.WARN)
      end
    end

    vim.keymap.set('n', '<leader>sq', auto_session.SaveSession, { desc = '[S]ession [Q]uicksave(CWD)' })

    vim.keymap.set('n', '<leader>ss', '<cmd>Telescope session-lens<CR>', { desc = '[S]earch [S]essions' })

    vim.keymap.set('n', '<leader>sd', delete_session_with_notification, { desc = '[S]ession [D]elete (CWD)' })
  end,
}
