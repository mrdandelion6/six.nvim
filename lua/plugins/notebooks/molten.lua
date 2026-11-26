if not vim.g.local_settings or not vim.g.local_settings.molten_support then
  return {}
end

-- credit: benlubas
-- this is the file for repl like functionality in code.
-- quarto.nvim is kinda related , as it lets me edit jupyter notebook type
-- files , but that has it's own config file.
local platform = require 'core.platform'
return {
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
    vim.g.molten_image_location = 'virt'
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
    vim.keymap.set(
      'n',
      '<localleader>ri',
      ':MoltenInit<CR>',
      { desc = 'Molten [R] [I]nitialize', silent = true }
    )

    -- non-blocking kernel startup. after :MoltenInit starts the kernel ,
    -- molten's tick timer (sync , every tick_rate ms) calls jupyter's
    -- wait_for_ready(timeout=0) until the kernel answers , which still waits
    -- up to 1s for a kernel_info reply , freezing nvim for most of the
    -- startup. so: pause that timer , wait for the kernel in a background
    -- python process with a fidget spinner , then resume the timer once the
    -- kernel answers (its first check then returns right away).
    local kernel_check = [[
import glob, os, sys, time
from jupyter_core.paths import jupyter_runtime_dir
from jupyter_client import BlockingKernelClient
since, deadline = float(sys.argv[1]), time.time() + 120
while True:
    files = [f for f in glob.glob(os.path.join(jupyter_runtime_dir(), "kernel-*.json"))
             if os.path.getmtime(f) >= since]
    if files:
        break
    if time.time() > deadline:
        sys.exit("no kernel connection file found")
    time.sleep(0.1)
c = BlockingKernelClient()
c.load_connection_file(max(files, key=os.path.getmtime))
c.start_channels()
c.wait_for_ready(timeout=max(1, deadline - time.time()))
c.stop_channels()
]]
    local init_started = 0 -- os.time() at MoltenInitPre , to find the new connection file
    local starting = 0 -- kernels still starting , the tick timer resumes at 0

    -- timer callbacks come through to lua as v:null , so filter in vimscript
    local function tick_timers()
      return vim.api.nvim_eval
        "map(filter(timer_info(), {_, t -> string(t.callback) ==# \"function('MoltenTick')\"}), {_, t -> t.id})"
    end

    vim.api.nvim_create_autocmd('User', {
      pattern = 'MoltenInitPre',
      callback = function()
        init_started = os.time() - 1
      end,
    })

    vim.api.nvim_create_autocmd('User', {
      pattern = 'MoltenInitPost',
      callback = function()
        -- runs inside :MoltenInit , before the first tick fires
        starting = starting + 1
        for _, id in ipairs(tick_timers()) do
          vim.fn.timer_pause(id, 1)
        end
        local ok, progress = pcall(require, 'fidget.progress')
        local handle = ok
            and progress.handle.create {
              title = 'starting kernel',
              lsp_client = { name = 'molten' },
            }
          or nil
        vim.system(
          { vim.g.python3_host_prog or 'python3', '-c', kernel_check, tostring(init_started) },
          { text = true },
          vim.schedule_wrap(function(res)
            starting = starting - 1
            if starting == 0 then
              for _, id in ipairs(tick_timers()) do
                vim.fn.timer_pause(id, 0)
              end
            end
            if handle then
              handle.message = res.code == 0 and 'ready' or 'failed'
              handle:finish()
            end
            if res.code ~= 0 then
              vim.notify(
                'molten: could not wait for the kernel in the background , molten will keep checking itself\n'
                  .. (res.stderr or ''),
                vim.log.levels.WARN
              )
            end
          end)
        )
      end,
    })

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

        vim.keymap.set(
          'n',
          '<localleader>rc',
          r.run_cell,
          { desc = 'Molten [R]un [C]ell', silent = true }
        )
        vim.keymap.set(
          'n',
          '<localleader>rA',
          r.run_all,
          { desc = 'Molten [R]un [A]ll Cells', silent = true }
        )
        vim.keymap.set('n', '<localleader>RA', function()
          r.run_all(true)
        end, { desc = 'Molten [R]un [A]ll Cells of All Languages', silent = true })

        -- setup some molten specific keybindings
        vim.keymap.set(
          'v',
          '<localleader>rv',
          ':<C-u>MoltenEvaluateVisual<CR>gv',
          { silent = true, desc = 'Molten [R]un [V]isual' }
        )
        vim.keymap.set(
          'n',
          '<localleader>ro',
          ':noautocmd MoltenEnterOutput<CR>',
          { desc = 'Molten [R] Open [O]utput', silent = true }
        )
        vim.keymap.set(
          'n',
          '<localleader>rp',
          ':MoltenImagePopup<CR>',
          { desc = 'Molten [R] [P]op Image', silent = true }
        )
        vim.keymap.set(
          'n',
          '<localleader>rd',
          ':MoltenDelete<CR>',
          { desc = 'Molten [R] [D]elete Cell', silent = true }
        )

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
}
