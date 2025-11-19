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

      to format files, this function does the following things in order:
        1. apply LSP or conform formatting based on filetype if applicable
        2. remove all trailing spaces, tabs, and carriage returns (CRLF -> LF)
           - skipped for filetypes whose formatters already handle this
        3. auto-indent lines with vim's built-in indentation engine
           - skipped if conform formatter or LSP is available for this filetype

      we use conform formatters for most languages (clang-format for c/cpp/cuda,
      prettier for js/ts/json/yaml/markdown, black for python, stylua for lua).
      for languages without a conform formatter, we fall back to LSP formatting
      if available (eg. rust-analyzer, pyright).

      LSP configurations can be found in lua/plugins/lsp.lua. conform
      configurations can be found in lua/plugins/conform.lua.

      if a filetype has neither a conform formatter nor an LSP (eg. .txt files),
      then only steps 2 and 3 will affect it, providing basic cleanup and
      indentation using vim's built-in capabilities.
  --]]
  local cursor_pos = vim.api.nvim_win_get_cursor(0)
  local conform = require 'conform'

  -- check if conform handles this filetype
  local has_conform_formatter = #conform.list_formatters() > 0

  -- also check if there is an lsp for this filetype
  local clients = vim.lsp.get_clients { bufnr = 0 }
  local has_lsp = #clients > 0

  -- step 1: format using conform or lsp
  if has_conform_formatter then -- always prefer conform first
    if start_line and end_line then
      -- FIXME: this doesn't seem to work. might be a formatter specific issue
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
  elseif has_lsp then -- lsp formatter
    vim.lsp.buf.format {
      async = false,
      range = start_line and {
        start = { start_line, 0 },
        ['end'] = { end_line, 0 },
      } or nil,
    }
  end

  -- step 2: remove trailing whitespace and carriage returns
  -- skip file types whose formatters handle this
  local formatters_handle_cleanup = {
    cuda = true,
    cpp = true,
    c = true,
    lua = true,
    python = true,
    javascript = true,
    typescript = true,
    json = true,
    yaml = true,
    markdown = true,
  }

  if start_line and end_line then
    if not formatters_handle_cleanup[vim.bo.filetype] then
      vim.cmd(string.format('%d,%ds/\\s\\+$//e', start_line, end_line))
      vim.cmd(string.format('%d,%ds/\\r\\+$//e', start_line, end_line))
    end
  else
    if not formatters_handle_cleanup[vim.bo.filetype] then
      vim.cmd [[%s/\s\+$//e]]
      vim.cmd [[%s/\r\+$//e]]
    end
  end

  -- step 3: auto-indent
  -- skip indentation if we have an lsp or formatter for the ft
  if not has_conform_formatter and not has_lsp then
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
