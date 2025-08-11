-- debug.lua
-- use the DAP plugin to debug your code.

return {
  'mfussenegger/nvim-dap',
  dependencies = {
    -- beautiful debugger ui
    'rcarriga/nvim-dap-ui',

    -- required dependency for nvim-dap-ui
    'nvim-neotest/nvim-nio',

    -- shows variable values inline while debugging
    'theHamsta/nvim-dap-virtual-text',

    -- telescope integration for debugging
    'nvim-telescope/telescope-dap.nvim',

    -- installs the debug adapters for you
    'williamboman/mason.nvim',
    'jay-babu/mason-nvim-dap.nvim',

    -- python debugging support
    'mfussenegger/nvim-dap-python',
  },

  keys = {
    -- basic debugging keymaps, feel free to change to your liking!
    {
      '<F1>',
      function()
        require('dap').step_into()
      end,
      desc = 'Debug: Step Into',
    },
    {
      '<F2>',
      function()
        require('dap').step_over()
      end,
      desc = 'Debug: Step Over',
    },
    {
      '<F3>',
      function()
        require('dap').step_out()
      end,
      desc = 'Debug: Step Out',
    },
    {
      '<F4>',
      function()
        require('dap').terminate()
      end,
      desc = 'Debug: Terminate',
    },
    {
      '<F5>',
      function()
        require('dap').continue()
      end,
      desc = 'Debug: Start/Continue',
    },
    {
      '<F6>',
      function()
        require('dap').restart()
      end,
      desc = 'Debug: Restart',
    },
    {
      '<leader>b',
      function()
        require('dap').toggle_breakpoint()
      end,
      desc = 'Debug: Toggle Breakpoint',
    },
    {
      '<leader>B',
      function()
        require('dap').set_breakpoint(vim.fn.input 'Breakpoint condition: ')
      end,
      desc = 'Debug: Set Breakpoint',
    },
    -- toggle to see last session result. without this, you can't see session output in case of unhandled exception.
    {
      '<F7>',
      function()
        require('dapui').toggle()
      end,
      desc = 'Debug: See last session result.',
    },
    {
      '<leader>fb',
      '<cmd>Telescope dap list_breakpoints<cr>',
      desc = '[F]ind [B]reakpoints',
    },
  },

  config = function()
    local dap = require 'dap'
    local dapui = require 'dapui'

    require('mason-nvim-dap').setup {
      -- makes a best effort to setup the various debuggers with
      -- reasonable debug configurations
      automatic_installation = true,

      -- you can provide additional configuration to the handlers,
      -- see mason-nvim-dap README for more information
      handlers = {},

      -- you'll need to check that you have the required things installed , see
      -- the setup guides in doc/
      ensure_installed = {
        -- update this to ensure that you have the debuggers for the langs you want
        -- C/C++
        'codelldb',
        -- python
        'debugpy',
        -- bash
        'bash-debug-adapter',
      },
    }

    -- dap ui setup
    -- for more information, see |:help nvim-dap-ui|
    dapui.setup {
      -- set icons to characters that are more likely to work in every terminal.
      icons = { expanded = '▾', collapsed = '▸', current_frame = '*' },
      controls = {
        icons = {
          pause = '⏸',
          play = '▶',
          step_into = '⏎',
          step_over = '⏭',
          step_out = '⏮',
          step_back = 'b',
          run_last = '▶▶',
          terminate = '⏹',
          disconnect = '⏏',
        },
      },
    }

    -- virtual text setup (shows variable values inline)
    require('nvim-dap-virtual-text').setup {
      enabled = true,
      enabled_commands = true,
      highlight_changed_variables = true,
      highlight_new_as_changed = false,
      show_stop_reason = true,
      commented = false,
      only_first_definition = true,
      all_references = false,
      filter_references_pattern = '<module',
      virt_text_pos = 'eol',
      all_frames = false,
      virt_lines = false,
      virt_text_win_col = nil,
    }

    -- telescope dap setup
    require('telescope').load_extension 'dap'

    -- change breakpoint icons
    vim.api.nvim_set_hl(0, 'DapBreak', { fg = '#e51400' })
    vim.api.nvim_set_hl(0, 'DapStop', { fg = '#ffcc00' })
    local breakpoint_icons = vim.g.have_nerd_font
    and { Breakpoint = '', BreakpointCondition = '', BreakpointRejected = '', LogPoint = '', Stopped = '' }
    or { Breakpoint = '●', BreakpointCondition = '⊜', BreakpointRejected = '⊘', LogPoint = '◆', Stopped = '⭔' }
    for type, icon in pairs(breakpoint_icons) do
      local tp = 'Dap' .. type
      local hl = (type == 'Stopped') and 'DapStop' or 'DapBreak'
      vim.fn.sign_define(tp, { text = icon, texthl = hl, numhl = hl })
    end

    dap.listeners.after.event_initialized['dapui_config'] = dapui.open
    dap.listeners.before.event_terminated['dapui_config'] = dapui.close
    dap.listeners.before.event_exited['dapui_config'] = dapui.close

    -- C/C++ setup
    dap.adapters.codelldb = {
      type = 'server',
      port = '${port}',
      executable = {
        command = vim.fn.exepath 'codelldb',
        args = { '--port', '${port}' },
      },
    }

    local cpp_base_config = {
      type = 'codelldb',
      request = 'launch',
      cwd = '${workspaceFolder}',
      stopOnEntry = false,
      setupCommands = {
        {
          text = 'settings set target.inline-breakpoint-strategy always',
          ignoreFailures = true,
        },
      },
    }

    local function cpp_executable_patterns(source_file)
      -- list of C++ executable names to try looking for (in order)
      return {
        source_file .. '.exe',
        source_file,
        source_file .. '.out',
        'main.exe',
        'a.exe',
        'main',
        'a',
        'main.out',
        'a.out',
      }
    end

    local function check_dir_cpp(executable_path)
      -- this function checks if a C/C++ executable exists within:
      -- project_root .. executable_path.  we check common executable patterns.
      -- if many found: display a picker , if one found: use it , if none found:
      -- ask for name manually

      local source_file = vim.fn.expand '%:t:r' -- get filename without extension
      local project_root = vim.fs.joinpath(vim.fn.getcwd())
      local executable_dir = vim.fs.joinpath(project_root, executable_path) .. '/'

      if vim.fn.isdirectory(executable_dir) ~= 1 then
        vim.notify("(nvim-dap) The path to check for C++ executable doesn't exist: " .. executable_dir,
          vim.log.levels.ERROR)
        -- fallback to manual input from project root
        return vim.fn.input('Path to executable: ', project_root .. '/', 'file')
      end

      local executable_patterns = cpp_executable_patterns(source_file)
      local found_executables = {}

      -- check which executables exist
      for _, pattern in ipairs(executable_patterns) do
        local full_path = vim.fs.joinpath(executable_dir, pattern)
        if vim.fn.filereadable(full_path) == 1 then
          table.insert(found_executables, full_path)
        end
      end

      -- if we found executables, let user choose or use first one
      if #found_executables > 0 then
        if #found_executables == 1 then
          -- only one found, use it directly but let user confirm/edit
          return vim.fn.input('Path to executable: ', found_executables[1], 'file')
        else
          -- multiple found, show a simple picker
          print 'Found multiple executables:'
          for i, exe in ipairs(found_executables) do
            print(string.format('%d: %s', i, vim.fn.fnamemodify(exe, ':t')))
          end

          local choice = vim.fn.input('Choose executable (1-' .. #found_executables .. ') or press Enter for first: ')
          local selected_idx = tonumber(choice) or 1

          if selected_idx >= 1 and selected_idx <= #found_executables then
            return vim.fn.input('Path to executable: ', found_executables[selected_idx], 'file')
          else
            return vim.fn.input('Path to executable: ', found_executables[1], 'file')
          end
        end
      else
        -- nothing found, fallback to manual input from executable_dir
        return vim.fn.input('Path to executable: ', executable_dir, 'file')
      end
    end

    local function cpp_get_args()
      local args_string = vim.fn.input 'Arguments (space-separated): '
      if args_string == '' then
        return {}
      end
      return vim.split(args_string, ' ')
    end

    -- dap configuartions for C++
    dap.configurations.cpp = {
      vim.tbl_extend('force', cpp_base_config, {
        name = 'Launch from build/Debug',
        program = function()
          return check_dir_cpp 'build/Debug'
        end,
        args = cpp_get_args,
      }),

      vim.tbl_extend('force', cpp_base_config, {
        name = 'Simple Launch',
        program = function()
          local source_file = vim.fn.expand '%:t:r' -- get filename without extension
          local source_dir = vim.fn.expand '%:p:h' .. '/'
          local executable_patterns = cpp_executable_patterns(source_file)

          -- check which executables exist
          for _, pattern in ipairs(executable_patterns) do
            local full_path = source_dir .. pattern
            if vim.fn.filereadable(full_path) == 1 then
              return full_path -- return first one found
            end
          end

          -- nothing found, fallback to manual input from source directory
          return vim.fn.input('Path to executable: ', source_dir, 'file')
        end,
      }),

      vim.tbl_extend('force', cpp_base_config, {
        name = 'Launch with CUDA debugging',
        program = function()
          return check_dir_cpp 'build/Debug'
        end,
        args = cpp_get_args,
        environment = {
          { name = 'CUDA_LAUNCH_BLOCKING',              value = '1' },
          { name = 'CUDA_DEBUGGER_SOFTWARE_PREEMPTION', value = '1' },
        },
      }),
    }

    -- same config for C and CUDA
    dap.configurations.c = dap.configurations.cpp
    dap.configurations.cuda = dap.configurations.cpp
    dap.configurations.hip = dap.configurations.cpp

    -- python setup
    require('dap-python').setup 'python'

    -- bash setup
    dap.adapters.bashdb = {
      type = 'executable',
      command = 'bash-debug-adapter',
      name = 'bashdb',
    }

    dap.configurations.sh = {
      {
        type = 'bashdb',
        request = 'launch',
        name = 'Launch file',
        showDebugOutput = true,
        pathBashdb = vim.fn.stdpath 'data' .. '/mason/packages/bash-debug-adapter/extension/bashdb_dir/bashdb',
        pathBashdbLib = vim.fn.stdpath 'data' .. '/mason/packages/bash-debug-adapter/extension/bashdb_dir',
        trace = true,
        file = '${file}',
        program = '${file}',
        cwd = '${workspaceFolder}',
        pathCat = 'cat',
        pathBash = '/bin/bash',
        pathMkfifo = 'mkfifo',
        pathPkill = 'pkill',
        args = {},
        env = {},
        terminalKind = 'integrated',
      },
    }
  end,
}
