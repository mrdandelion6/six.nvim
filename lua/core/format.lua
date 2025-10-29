-- format.lua is the entry point for all formatting and autoformatting for my
-- nvim config.

vim.g.format_on_save = true
vim.b.format_on_save = true

local function format_range(start_line, end_line)
  --[[
      this function handles the formatting for all files. it should be the only
      route for files to be directly formatted by the user. a range can be
      specified with start_line and end_line. otherwise the entire file is
      formatted.

      to format files , this function does the following things in order:
        1. apply LSP or conform formatting based on filetype if applicable
        2. remove all trailing spaces , tabs , and carriage returns (CRLF -> LF)
        3. auto-indent lines with vim's built-in indentation engine

      we use LSP formatting for languages with good quality LSPs (clangd). for
      languages with poor LSP formatting (eg. pyright) , we use conform which
      wraps around other formatting tools (eg. black for python , prettier for
      javascript).

      LSP configurations can be found in lua/plugins/lsp.lua. this does most of
      the heavy lifting using the nvim-lspconfig plugin which uses installed
      language server protocols such as clangd , rust-analyzer , pyright , etc.
      if a filetype has no matching LSP (eg. file.txt) , then only steps 2 and 3
      will affect it. for certain filetypes like .c and .cpp , step 3 is skipped
      as to not conflict with LSPs like clangd.
  --]]
  local cursor_pos = vim.api.nvim_win_get_cursor(0)

  -- check if conform handles this filetype
  local conform = require 'conform'
  local has_conform_formatter = #conform.list_formatters() > 0

  -- step 1: format using conform or lsp
  if has_conform_formatter then
    if start_line and end_line then
      conform.format {
        range = {
          start = { start_line, 0 },
          ['end'] = { end_line, 0 },
        },
        async = false,
      }
    else
      conform.format { async = false }
    end
  else -- lsp formatter
    vim.lsp.buf.format {
      async = false,
      range = start_line and {
        start = { start_line, 0 },
        ['end'] = { end_line, 0 },
      } or nil,
    }
  end

  -- step 2: remove trailing whitespace and carriage returns
  if start_line and end_line then
    -- apply to specific range
    vim.cmd(string.format('%d,%ds/\\s\\+$//e', start_line, end_line))
    vim.cmd(string.format('%d,%ds/\\r\\+$//e', start_line, end_line))
  else
    -- apply to entire file
    vim.cmd [[%s/\s\+$//e]]
    vim.cmd [[%s/\r\+$//e]]
  end

  -- step 3: auto-indent. skip filetypes with good formatters
  local skip_autoindent = { c = true, cpp = true, lua = true, python = true, javascript = true }
  if not skip_autoindent[vim.bo.filetype] then
    if start_line and end_line then
      vim.cmd(string.format('normal! %dgg==%dgg', start_line, end_line - start_line + 1))
    else
      vim.cmd 'normal! gg=G'
    end
  end

  -- restore cursor position
  local success = pcall(function()
    vim.api.nvim_win_set_cursor(0, cursor_pos)
  end)

  if not success then
    local line_count = vim.api.nvim_buf_line_count(0)
    local last_line = vim.api.nvim_buf_get_lines(0, -2, -1, false)[1] or ''
    vim.api.nvim_win_set_cursor(0, { line_count, #last_line })
  end

  Center_cursor()
end

--[[
********************************************************************************
                                    COMMANDS
********************************************************************************
--]]

vim.api.nvim_create_user_command('Format', function(opts)
  -- user command that works in visual mode and normal mode
  if opts.range > 0 then
    -- visual selection or range provided
    format_range(opts.line1, opts.line2)
  else
    -- entire file
    format_range()
  end
end, {
  desc = 'Format the selected code or entire file',
  range = true, -- this allows the command to work with visual selections
})

-- format on save should start as true for every buffer
vim.api.nvim_create_autocmd('BufAdd', {
  callback = function(args)
    vim.b[args.buf].format_on_save = true
  end,
})

vim.api.nvim_create_autocmd('BufWritePre', {
  desc = 'Format on save using LSP',
  group = vim.api.nvim_create_augroup('format_on_save', { clear = true }),
  callback = function()
    local bufnr = vim.api.nvim_get_current_buf()

    -- skip if binary file
    if vim.bo[bufnr].binary then
      return
    end

    -- skip if file is too large (> 1MB)
    local max_filesize = 1024 * 1024 -- 1MB
    local ok, stats = pcall(vim.uv.fs_stat, vim.api.nvim_buf_get_name(bufnr))
    if ok and stats and stats.size > max_filesize then
      return
    end

    -- skip special buffer types
    local buftype = vim.bo[bufnr].buftype
    if buftype ~= '' then -- non-empty means special (quickfix, terminal, etc.)
      return
    end

    -- skip if readonly
    if vim.bo[bufnr].readonly then
      return
    end

    -- skip certain filetypes entirely
    local skip_filetypes = { 'gitcommit', 'gitrebase', 'help', 'man' }
    if vim.tbl_contains(skip_filetypes, vim.bo[bufnr].filetype) then
      return
    end

    if vim.g.format_on_save and vim.b.format_on_save then
      -- check if this file is in our exclude_autoformat
      local file_path = vim.fn.expand '%:p'
      if vim.g.local_settings and vim.g.local_settings.exclude_autoformat then
        for _, pattern in ipairs(vim.g.local_settings.exclude_autoformat) do
          if file_path:match(pattern) then
            return -- match found in exclude_autoformat
          end
        end
      end
    else
      return -- global or local format_on_save is false
    end

    format_range()
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
