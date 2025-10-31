-- credit: benlubas
-- this is the file for repl like functionality in code.
-- quarto.nvim is kinda related , as it lets me edit jupyter notebook type
-- files , but that has it's own config file.
local platform = require 'core.platform'
return {
  {
    'benlubas/molten-nvim',
    -- enabled = false,
    dependencies = { 'image.nvim' },

    -- this is just to avoid loading image.nvim , loading molten at the start has minimal startup time impact
    ft = { 'python', 'norg', 'markdown', 'quarto' },

    init = function()
      if platform.is_wsl() then
        vim.g.molten_open_cmd = 'wslview'
      elseif platform.is_linux() then
        vim.g.molten_open_cmd = 'firefox'
      end

      -- vim.g.molten_auto_image_popup = true
      -- vim.g.molten_show_mimetype_debug = true
      vim.g.molten_auto_open_output = false
      vim.g.molten_image_location = 'float'
      vim.g.molten_image_provider = 'image.nvim'
      -- vim.g.molten_output_show_more = true
      vim.g.molten_output_win_border = { '', '━', '', '' }
      vim.g.molten_output_win_max_height = 12
      -- vim.g.molten_output_virt_lines = true
      vim.g.molten_virt_text_output = true
      vim.g.molten_use_border_highlights = true
      vim.g.molten_virt_lines_off_by_1 = true
      vim.g.molten_wrap_output = true
      vim.g.molten_tick_rate = 142
      vim.g.molten_enter_output_behavior = 'open_and_enter'

      -- initialize molten
      vim.keymap.set('n', '<localleader>ri', ':MoltenInit<CR>', { desc = 'Molten [R] [I]nitialize', silent = true })

      -- keymaps that only appear after molten init
      vim.api.nvim_create_autocmd('User', {
        pattern = 'MoltenInitPost',
        callback = function()
          -- quarto code runner mappings. quarto is a wrapper around molten that
          -- intelligently identifies code blocks in markdown.
          local r = require 'quarto.runner'

          --[[
          **********************************************************************
                                         KEYBINDS
          **********************************************************************
          --]]

          vim.keymap.set('n', '<localleader>rc', r.run_cell, { desc = 'run cell', silent = true })
          vim.keymap.set('n', '<localleader>rA', r.run_all, { desc = 'Molten [R]un [A]ll Cells', silent = true })
          vim.keymap.set('n', '<localleader>RA', function()
            r.run_all(true)
          end, { desc = 'Molten [R]un [A]ll Cells of All Languages', silent = true })

          -- setup some molten specific keybindings
          vim.keymap.set('v', '<localleader>rv', ':<C-u>MoltenEvaluateVisual<CR>gv', { silent = true, desc = 'Molten [R]un [V]isual' })
          vim.keymap.set('n', '<localleader>ro', ':noautocmd MoltenEnterOutput<CR>', { desc = 'Molten [R] Open [O]utput', silent = true })
          vim.keymap.set('n', '<localleader>rd', ':MoltenDelete<CR>', { desc = 'Molten [R] [D]elete Cell', silent = true })

          local open = false
          vim.keymap.set('n', '<localleader>rt', function()
            open = not open
            vim.fn.MoltenUpdateOption('auto_open_output', open)
          end)

          -- if we're in a python file, change the configuration a little
          if vim.bo.filetype == 'python' then
            vim.fn.MoltenUpdateOption('molten_virt_lines_off_by_1', false)
            vim.fn.MoltenUpdateOption('molten_virt_text_output', false)
          end
        end,
      })

      -- change the configuration when editing a python file
      vim.api.nvim_create_autocmd('BufEnter', {
        pattern = '*.py',
        callback = function(e)
          if string.match(e.file, '.otter.') then
            return
          end
          if require('molten.status').initialized() == 'Molten' then
            vim.fn.MoltenUpdateOption('molten_virt_lines_off_by_1', false)
            vim.fn.MoltenUpdateOption('molten_virt_text_output', false)
          end
        end,
      })

      -- undo those config changes when we go back to a markdown or quarto file
      vim.api.nvim_create_autocmd('BufEnter', {
        pattern = { '*.qmd', '*.md', '*.ipynb' },
        callback = function()
          if require('molten.status').initialized() == 'Molten' then
            vim.fn.MoltenUpdateOption('molten_virt_lines_off_by_1', true)
            vim.fn.MoltenUpdateOption('molten_virt_text_output', true)
          end
        end,
      })
    end,
  },
}
