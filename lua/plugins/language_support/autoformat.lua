vim.g.format_on_save = true
vim.b.format_on_save = true

-- TODO: consider migrating entirely to conform.nvim
vim.api.nvim_create_autocmd('BufWritePre', {
  desc = 'Format on save using LSP',
  group = vim.api.nvim_create_augroup('format_on_save', { clear = true }),
  callback = function()
    -- vim.b.format_on_save can be nil , treat as true !
    if vim.g.format_on_save and (vim.b.format_on_save ~= false) then
      -- check if this file is in our exclude_autoformat
      local file_path = vim.fn.expand '%:p'
      local should_format = true
      if vim.g.local_settings and vim.g.local_settings.exclude_autoformat then
        for _, pattern in ipairs(vim.g.local_settings.exclude_autoformat) do
          if file_path:match(pattern) then
            should_format = false
            break
          end
        end
      end

      if should_format then
        local cursor_pos = vim.api.nvim_win_get_cursor(0)

        -- calls your lsp servers from lsp.lua
        vim.lsp.buf.format { async = false }

        -- remove trailing stuff
        vim.cmd [[%s/\s\+$//e]]
        vim.cmd [[%s/\r\+$//e]]

        -- skip gg=g for c/c++ files since it ignores clang-format comments
        -- if not (vim.bo.filetype == 'c' or vim.bo.filetype == 'cpp') then
        --   vim.cmd 'normal! gg=G'
        -- end

        -- TODO: delete this later when u figure out the bug causing clangd to
        -- receive no args , and uncomment the above
        vim.cmd 'normal! gg=G'

        -- this could fail if we are at EOF that had trailing lines.
        local success = pcall(function()
          vim.api.nvim_win_set_cursor(0, cursor_pos)
        end)

        -- if it fails , then we were at some empty lines at EOF that got
        -- got removed. just go back to new EOF.
        if not success then
          local line_count = vim.api.nvim_buf_line_count(0)
          local last_line = vim.api.nvim_buf_get_lines(0, -2, -1, false)[1] or ''
          vim.api.nvim_win_set_cursor(0, { line_count, #last_line })
        end

        Center_cursor()
      end
    end
  end,
})

vim.api.nvim_create_user_command('ToggleFormatOnSave', function()
  vim.g.format_on_save = not vim.g.format_on_save
end, {})

vim.api.nvim_create_user_command('ToggleFormatOnSaveBuffer', function()
  vim.b.format_on_save = not vim.b.format_on_save
end, {})

vim.keymap.set('n', '<leader>tf', ':ToggleFormatOnSaveBuffer<CR>', { desc = '[T]oggle [F]ormat on Save for Buffer' })

vim.api.nvim_create_user_command('W', function()
  -- write without autoformat
  local prev_state = vim.g.format_on_save
  vim.b.format_on_save = false
  vim.cmd 'write'
  vim.b.format_on_save = prev_state
end, {})

return { -- code autoformat
  'stevearc/conform.nvim',
  event = { 'BufWritePre' },
  cmd = { 'ConformInfo' },
  opts = {
    notify_on_error = false,
    format_on_save = function(bufnr)
      -- respect our local format settings
      if not vim.g.format_on_save or not vim.b.format_on_save then
        return nil -- disable formatting
      end

      -- disable "format_on_save lsp_fallback" for languages that don't
      -- have a well standardized coding style. you can add additional
      -- languages here or re-enable it for the disabled ones.
      local disable_filetypes = { c = true, cpp = true }
      local lsp_format_opt
      if disable_filetypes[vim.bo[bufnr].filetype] then
        lsp_format_opt = 'never'
      else
        lsp_format_opt = 'fallback'
      end
      return {
        timeout_ms = 500,
        lsp_format = lsp_format_opt,
      }
    end,
    formatters_by_ft = {
      lua = { 'stylua' },
      -- conform can also run multiple formatters sequentially
      -- python = { "isort", "black" },
      --
      -- you can use 'stop_after_first' to run the first available formatter from the list
      -- javascript = { "prettierd", "prettier", stop_after_first = true },
    },
  },
}
