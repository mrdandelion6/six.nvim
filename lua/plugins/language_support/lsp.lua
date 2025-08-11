return {
  { -- `lazydev` configures Lua LSP for your Neovim config, runtime and plugins
    -- used for completion, annotations and signatures of Neovim apis
    'folke/lazydev.nvim',
    ft = 'lua',
    opts = {
      library = {
        -- load luvit types when the `vim.uv` word is found
        { path = 'luvit-meta/library', words = { 'vim%.uv' } },
      },
    },
  },

  -- more nvim lsp. provides type definitons for vim.uv.
  { 'Bilal2453/luvit-meta', lazy = true },

  {
    -- main lsp configuration
    'neovim/nvim-lspconfig',
    dependencies = {
      -- automatically install lsps and related tools to stdpath for neovim
      { 'williamboman/mason.nvim', config = true }, -- must be loaded before dependants
      'williamboman/mason-lspconfig.nvim',
      'WhoIsSethDaniel/mason-tool-installer.nvim',

      -- useful status updates for LSP.
      -- `opts = {}` is the same as calling `require('fidget').setup({})`
      {
        'j-hui/fidget.nvim',
        opts = {
          notification = {
            window = {
              border = 'rounded',
              relative = 'win',
            },
            view = {
              stack_upwards = true,
              icon_separator = ' ',
              group_separator = '---',
              group_separator_hl = 'Comment',
            },
            styles = {
              -- this changes the transparency
              minimal = false, -- setting minimal to false makes it use background
            },
          },
        },
      },

      -- allows extra capabilities provided by nvim-cmp
      'hrsh7th/cmp-nvim-lsp',
    },
    config = function()
      -- brief aside: **what is lsp?**
      --
      -- lsp is an initialism you've probably heard, but might not understand what it is.
      --
      -- lsp stands for language server protocol. it's a protocol that helps editors
      -- and language tooling communicate in a standardized fashion.
      --
      -- in general, you have a "server" which is some tool built to understand a particular
      -- language (such as `gopls`, `lua_ls`, `rust_analyzer`, etc.). these language servers
      -- (sometimes called lsp servers, but that's kind of like atm machine) are standalone
      -- processes that communicate with some "client" - in this case, neovim!
      --
      -- lsp provides neovim with features like:
      --  - go to definition
      --  - find references
      --  - autocompletion
      --  - symbol search
      --  - and more!
      --
      -- thus, language servers are external tools that must be installed separately from
      -- neovim. this is where `mason` and related plugins come into play.
      --
      -- if you're wondering about lsp vs treesitter, you can check out the wonderfully
      -- and elegantly composed help section, `:help lsp-vs-treesitter`

      --  this function gets run when an LSP attaches to a particular buffer.
      --    that is to say, every time a new file is opened that is associated with
      --    an lsp (for example, opening `main.rs` is associated with `rust_analyzer`) this
      --    function will be executed to configure the current buffer

      -- patterns to exclude from autoformat
      if vim.g.local_settings then
        local exclude_autoformat = vim.g.local_settings.exclude_autoformat
        if not exclude_autoformat then
          print 'ERROR: (autoformat.lua): vim.g.local_settings.exclude_autoformat is nil'
          exclude_autoformat = {}
        end
      else
        print 'ERROR: (lsp.lua): vim.g.local_settings is nil'
      end

      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true }),
        callback = function(event)
          -- create a function that lets us more easily define mappings specific
          -- for LSP related items. It sets the mode, buffer and description for us each time.
          local map = function(keys, func, desc, mode)
            mode = mode or 'n'
            vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
          end

          -- jump to the definition of the word under your cursor.
          --  this is where a variable was first declared, or where a function is defined, etc.
          --  to jump back, press <C-t>.
          map('gd', require('telescope.builtin').lsp_definitions, '[G]oto [D]efinition')

          -- find references for the word under your cursor.
          map('gr', require('telescope.builtin').lsp_references, '[G]oto [R]eferences')

          -- jump to the implementation of the word under your cursor.
          --  useful when your language has ways of declaring types without an actual implementation.
          map('gI', require('telescope.builtin').lsp_implementations, '[G]oto [I]mplementation')

          -- go to the type of the word under your cursor.
          --  useful when you're not sure what type a variable is and you want to see
          --  the definition of its *type*, not where it was *defined*.
          map('gt', require('telescope.builtin').lsp_type_definitions, '[G]oto [T]ype')

          -- fuzzy find all the symbols in your current document.
          --  symbols are things like variables, functions, types, etc.
          map('<leader>fs', require('telescope.builtin').lsp_document_symbols, '[F]ind Document [S]ymbols')

          -- fuzzy find all the symbols in your current workspace.
          --  similar to document symbols, except searches over your entire project.
          map('<leader>fS', require('telescope.builtin').lsp_dynamic_workspace_symbols, '[F]ind Workspace [S]ymbols')

          -- rename the variable under your cursor.
          --  most Language Servers support renaming across files, etc.
          map('<leader>rn', vim.lsp.buf.rename, '[R]e[n]ame')

          -- execute a code action, usually your cursor needs to be on top of an error
          -- or a suggestion from your LSP for this to activate.
          map('<leader>ca', vim.lsp.buf.code_action, '[C]ode [A]ction', { 'n', 'x' })

          -- this is not goto definition, this is goto declaration.
          -- for example, in c this would take you to the header.
          map('gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')

          -- the following two autocommands are used to highlight references of the word under your cursor when your cursor rests there for a little while.
          -- when you move your cursor, the highlights will be cleared (the second autocommand).
          local client = vim.lsp.get_client_by_id(event.data.client_id)
          if client and client.supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight) then
            local highlight_augroup = vim.api.nvim_create_augroup('kickstart-lsp-highlight', { clear = false })
            vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
              buffer = event.buf,
              group = highlight_augroup,
              callback = vim.lsp.buf.document_highlight,
            })

            vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
              buffer = event.buf,
              group = highlight_augroup,
              callback = vim.lsp.buf.clear_references,
            })

            vim.api.nvim_create_autocmd('LspDetach', {
              group = vim.api.nvim_create_augroup('kickstart-lsp-detach', { clear = true }),
              callback = function(event2)
                vim.lsp.buf.clear_references()
                vim.api.nvim_clear_autocmds { group = 'kickstart-lsp-highlight', buffer = event2.buf }
              end,
            })
          end

          -- the following code creates a keymap to toggle inlay hints in your
          -- code, if the language server you are using supports them
          -- this may be unwanted, since they displace some of your code
          if client and client.supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint) then
            map('<leader>th', function()
              vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf })
            end, '[T]oggle Inlay [H]ints')
          end
        end,
      })

      -- change diagnostic symbols in the sign column (gutter)
      if vim.g.have_nerd_font then
        local signs = { ERROR = '', WARN = '', INFO = '', HINT = '' }
        local diagnostic_signs = {}
        for type, icon in pairs(signs) do
          diagnostic_signs[vim.diagnostic.severity[type]] = icon
        end
        vim.diagnostic.config { signs = { text = diagnostic_signs } }
      end

      -- LSP servers and clients are able to communicate to each other what features they support.
      --  by default, Neovim doesn't support everything that is in the LSP specification.
      --  when you add nvim-cmp, luasnip, etc. Neovim now has *more* capabilities.
      --  so, we create new capabilities with nvim cmp, and then broadcast that to the servers.
      local capabilities = vim.lsp.protocol.make_client_capabilities()
      capabilities = vim.tbl_deep_extend('force', capabilities, require('cmp_nvim_lsp').default_capabilities())

      -- enable the following language servers
      --  feel free to add/remove any LSPs that you want here. they will automatically be installed.
      --
      --  add any additional override configuration in the following tables. Available keys are:
      --  - cmd (table): Override the default command used to start the server
      --  - filetypes (table): Override the default list of associated filetypes for the server
      --  - capabilities (table): Override fields in capabilities. Can be used to disable certain LSP features.
      --  - settings (table): Override the default settings passed when initializing the server.
      --        For example, to see the options for `lua_ls`, you could go to: https://luals.github.io/wiki/settings/

      local default_settings = {
        capabilities = capabilities,
        flags = {
          debounce_text_changes = 150,
        },
        settings = {
          formatting = {
            trimTrailingWhitespace = true,
            trimFinalNewlines = true,
            insertFinalNewline = true,
          },
        },
        editor = {
          tabSize = 4,
          insertSpaces = true,
        },
        -- unix style endings
        init_options = {
          documentFormatting = true,
          documentRangeFormatting = true,
        },
      }

      -- TODO: have persistance for ignored files in .localsettings as an array
      -- ignore lsp for files
      -- local layout_path = vim.fn.stdpath 'config' .. '/.localsettings.json'

      local servers = {
        clangd = vim.tbl_deep_extend('force', default_settings, {
          filetypes = { 'c', 'cpp', 'objc', 'objcpp', 'cuda' },
          cmd = {
            'clangd',
            '--enable-config',
            '--background-index',
            '--fallback-style={IndentWidth: 4, TabWidth: 4, UseTab: Never}',
            '--compile-commands-dir=.', -- project root
          },
          settings = {
            clangd = {
              formatting = {
                style = {
                  IndentWidth = 4,
                  TabWidth = 4,
                  UseTab = 'Never',
                },
              },
            },
          },
        }),

        pyright = vim.tbl_deep_extend('force', default_settings, {
          settings = {
            python = {
              analysis = {
                typeCheckingMode = 'basic',
                diagnosticSeverityOverrides = {
                  reportMissingImports = 'none',
                  reportMissingModuleSource = 'none',
                  reportImportCycles = 'none',
                },
              },
              formatting = {
                provider = 'black',
              },
            },
          },
        }),

        texlab = vim.tbl_deep_extend('force', default_settings, {
          settings = {
            texlab = {
              auxDirectory = '.tex', -- matches your vimtex aux_dir
              bibtexFormatter = 'texlab',
              build = {
                executable = 'latexmk',
                args = { '-pdf', '-interaction=nonstopmode', '-synctex=1', '%f' },
                onSave = false, -- let vimtex handle compilation
                forwardSearchAfter = false,
              },
              chktex = {
                onOpenAndSave = true,
                onEdit = false,
              },
              diagnosticsDelay = 300,
              formatterLineLength = 80,
              forwardSearch = {
                executable = nil, -- let vimtex handle forward search
                args = {},
              },
              latexFormatter = 'latexindent',
              latexindent = {
                ['local'] = nil,
                modifyLineBreaks = false,
              },
            },
          },
        }),

        jdtls = vim.tbl_deep_extend('force', default_settings, {
          filetypes = { 'java' },
        }),

        -- TODO: figure out how to get mason to not throw an error
        -- sourcekit = vim.tbl_deep_extend('force', default_settings, {
        --   cmd = { sourcekit_script },
        --   filetypes = { 'swift' },
        --   root_dir = require('lspconfig.util').root_pattern('Package.swift', '.git'),
        -- }),

        bashls = {},
        rust_analyzer = {},
        verible = {},

        -- some languages (like typescript) have entire language plugins that can be useful:
        --    https://github.com/pmizio/typescript-tools.nvim
        --
        -- but for many setups, the LSP (`ts_ls`) will work just fine
        ts_ls = {},
        lua_ls = {
          -- cmd = { ... },
          -- filetypes = { ... },
          -- capabilities = {},
          settings = {
            Lua = {
              completion = {
                callSnippet = 'Replace',
              },
              -- you can toggle below to ignore Lua_LS's noisy `missing-fields` warnings
              -- diagnostics = { disable = { 'missing-fields' } },
            },
          },
        },
        cssls = vim.tbl_deep_extend('force', default_settings, {}),
        emmet_ls = vim.tbl_deep_extend('force', default_settings, {
          filetypes = { 'html', 'typescriptreact', 'javascriptreact', 'css', 'sass', 'scss', 'less' },
        }),
      }

      -- ensure the servers and tools above are installed
      --  to check the current status of installed tools and/or manually install
      --  other tools, you can run
      --    :Mason
      --
      --  you can press `g?` for help in this menu.
      require('mason').setup()

      -- you can add other tools here that you want Mason to install
      -- for you, so that they are available from within Neovim.
      local ensure_installed = vim.tbl_keys(servers or {})
      vim.list_extend(ensure_installed, {
        'stylua',       -- lua formatter
        'clang-format', -- c/c++
        'prettier',     -- js/ts
        'black',        -- python
      })
      require('mason-tool-installer').setup { ensure_installed = ensure_installed }

      require('mason-lspconfig').setup {
        handlers = {
          function(server_name)
            local server = servers[server_name] or {}
            -- this handles overriding only values explicitly passed
            -- by the server configuration above. Useful when disabling
            -- certain features of an LSP (for example, turning off formatting for ts_ls)
            server.capabilities = vim.tbl_deep_extend('force', {}, capabilities, server.capabilities or {})
            require('lspconfig')[server_name].setup(server)
          end,
        },
      }
    end,
  },
}
