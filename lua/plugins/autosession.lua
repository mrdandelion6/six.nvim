return { -- For persisting neovim sessions.
  'rmagatti/auto-session',
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

    -- Automatically save the session when exiting Nvim if session exists.
    vim.api.nvim_create_autocmd('VimLeavePre', {
      callback = function()
        if auto_session.session_exists_for_cwd() then
          auto_session.SaveSession()
        end
      end,
    })

    -- If opened CWD isn't an existing session, spawn a terminal on the right
    vim.api.nvim_create_autocmd('VimEnter', {
      callback = function()
        if not auto_session.session_exists_for_cwd() then
          vim.cmd 'vsplit | wincmd l'
          local width = math.floor(vim.o.columns * 0.35)
          vim.cmd('vertical resize ' .. width .. ' | terminal')
          vim.cmd 'wincmd h'
        end
      end,
    })

    -- Added this because no message was displaying automatically.
    local function delete_session_with_notification()
      if auto_session.session_exists_for_cwd() then
        auto_session.DeleteSession()
        vim.notify('Deleted session: ' .. vim.fn.getcwd(), vim.log.levels.INFO)
      else
        vim.notify('Session does not exist: ' .. vim.fn.getcwd(), vim.log.levels.WARN)
      end
    end

    vim.keymap.set('n', '<leader>sq', auto_session.SaveSession, { desc = '[S]ession [Q]uicksave(CWD)' })

    vim.keymap.set('n', '<leader>ss', require('auto-session.session-lens').search_session, { desc = '[S]earch [S]essions' })

    vim.keymap.set('n', '<leader>sd', delete_session_with_notification, { desc = '[S]ession [D]elete (CWD)' })
  end,
}
