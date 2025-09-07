return {
  "hat0uma/csvview.nvim",
  opts = {
    parser = { comments = { "#", "//" } },
    -- no keymaps in opts - we'll set them manually per buffer
  },
  ft = "csv",
  config = function(_, opts)
    -- Set up the plugin without keymaps first
    if not vim.g.loaded_csv_view then
      require("csvview").setup(opts)
      vim.g.loaded_csv_view = true
    end

    -- function to set csv keymaps for a specific buffer
    local function setup_csv_keymaps(buf)
      local keymap_opts = { buffer = buf, silent = true }

      -- text objects
      vim.keymap.set({ "o", "x" }, "af", function()
        require('csvview.textobject').field(buf, { include_delimiter = true })
      end, keymap_opts)

      -- layout specific
      if vim.g.local_settings then
        if vim.g.local_settings.layout == 'colemak' then
          vim.keymap.set({ "o", "x" }, "lf", function()
            require('csvview.textobject').field(buf, { include_delimiter = false })
          end, keymap_opts)
        end
      else
        vim.keymap.set({ "o", "x" }, "if", function()
          require('csvview.textobject').field(buf, { include_delimiter = false })
        end, keymap_opts)
      end

      -- pure arrow key navigation
      vim.keymap.set({ "n", "v" }, "<Left>", function()
        require('csvview.jump').prev_field_end(buf)
      end, keymap_opts)
      vim.keymap.set({ "n", "v" }, "<Right>", function()
        require('csvview.jump').next_field_end(buf)
      end, keymap_opts)
      vim.keymap.set({ "n", "v" }, "<Down>", function()
        require('csvview.jump').next_field_start(buf)
      end, keymap_opts)
      vim.keymap.set({ "n", "v" }, "<Up>", function()
        require('csvview.jump').prev_field_start(buf)
      end, keymap_opts)
    end

    -- check existing csv buffers
    vim.schedule(function()
      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(buf) then
          local filetype = vim.api.nvim_get_option_value('filetype', { buf = buf })
          if filetype == 'csv' then
            vim.api.nvim_buf_call(buf, function()
              vim.cmd("CsvViewEnable display_mode=border header_lnum=1")
              setup_csv_keymaps(buf)
            end)
          end
        end
      end
    end)

    -- autocommand for new csv files
    vim.api.nvim_create_autocmd("BufRead", {
      pattern = "*.csv",
      callback = function()
        local buf = vim.api.nvim_get_current_buf()
        vim.cmd("CsvViewEnable display_mode=border header_lnum=1")
        setup_csv_keymaps(buf)
      end,
    })
  end,
}
