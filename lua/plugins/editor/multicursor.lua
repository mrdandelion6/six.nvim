return {
  'mg979/vim-visual-multi', -- allows for multi selection in buffer.
  branch = 'master',
  lazy = false,
  init = function()
    vim.g.VM_default_mappings = 0
    vim.g.VM_mouse_mappings = 0

    local common_VM_maps = {
      ['Select All'] = '<Leader>aa',
      ['Visual All'] = '<Leader>aa',
      ['Visual Cursors'] = '<Leader>ad',
      ['Skip Region'] = 'b',
    }

    vim.g.VM_maps = common_VM_maps

    -- set keyboard layout specific maps
    local function set_layout_maps()
      if vim.g.local_settings == nil then
        print 'ERROR (multicursor.lua): vim.g.local_settings is nil'
        return
      end

      local layout = vim.g.local_settings.keyboard_layout
      local new_VM_maps = vim.deepcopy(common_VM_maps)

      if layout == nil then
        print 'ERROR (multicursor.lua): vim.g.local_settings.keyboard_layout is nil'
        return
      end

      if layout == 'colemak' then
        local remaps = require 'core.keymaps'

        -- set VM_maps
        new_VM_maps['Find Under'] = '<Leader>ah'
        new_VM_maps['Find Subword Under'] = '<Leader>ah'
        new_VM_maps['Add Cursor Down'] = '<Leader>an'
        new_VM_maps['Add Cursor Up'] = '<Leader>ae'
        new_VM_maps['Find Next'] = 'h'
        new_VM_maps['Find Prev'] = 'H'
        new_VM_maps['i'] = 'l'
        new_VM_maps['I'] = 'L'
        vim.g.VM_maps = new_VM_maps

        -- set VM_custom_motions
        vim.g.VM_custom_motions = {
          ['k'] = remaps['k'],
          ['n'] = remaps['n'], -- FIXME: figure out why 'n' won't work for down movement
          ['e'] = remaps['e'],
          ['i'] = remaps['i'],
        }
      elseif layout == 'qwerty' then
        -- set VM_maps
        new_VM_maps['Find Under'] = '<Leader>an'
        new_VM_maps['Find Subword Under'] = '<Leader>an'
        new_VM_maps['Add Cursor Down'] = '<Leader>aj'
        new_VM_maps['Add Cursor Up'] = '<Leader>ak'
        new_VM_maps['Find Next'] = 'n'
        new_VM_maps['Find Prev'] = 'N'
        vim.g.VM_maps = new_VM_maps

        -- reset VM_custom_motions
        vim.g.VM_custom_motions = vim.empty_dict()
      else
        print('ERROR (multicursor.lua): vim.g.local_settings.keyboard_layout: ' .. layout .. ' not recognized')
        return
      end
    end

    local group = vim.api.nvim_create_augroup('visual_multi_keyboard_layout', {
      clear = true,
    })

    local refresh_pending = false

    local function rebuild_visual_multi_maps()
      local vm = vim.g.Vm or {}

      -- remove permanent mappings generated for the previous layout.
      for _, command in ipairs(vm.unmaps or {}) do
        vim.cmd(command)
      end

      -- discard buffer-local mapping caches. they will be rebuilt the next
      -- time visual multi starts in each buffer.
      for _, buffer in ipairs(vim.api.nvim_list_bufs()) do
        pcall(vim.api.nvim_buf_del_var, buffer, 'VM_maps')
        pcall(vim.api.nvim_buf_del_var, buffer, 'VM_unmaps')
      end

      -- rebuild and apply permanent mappings from the new vm_maps.
      vim.fn['vm#maps#default']()
    end

    local function refresh_layout_maps()
      -- update vm_maps and vm_custom_motions first.
      set_layout_maps()

      -- during lazy.nvim's init phase, visual multi is not loaded yet.
      if vim.g.loaded_visual_multi ~= 1 then
        return
      end

      -- rebuilding during an active vm session would interfere with its
      -- cleanup, so wait until the session exits.
      if vim.g.Vm.mappings_enabled == 1 then
        if not refresh_pending then
          refresh_pending = true

          vim.api.nvim_create_autocmd('User', {
            group = group,
            pattern = 'visual_multi_exit',
            once = true,
            callback = function()
              vim.schedule(function()
                refresh_pending = false
                rebuild_visual_multi_maps()
              end)
            end,
          })
        end

        return
      end

      rebuild_visual_multi_maps()
    end

    vim.api.nvim_create_autocmd('User', {
      group = group,
      pattern = 'KeyboardLayoutChanged',
      callback = refresh_layout_maps,
    })

    set_layout_maps()
  end,
}
