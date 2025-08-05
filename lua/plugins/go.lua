return {
  -- Import the LazyVim Go extra for proper LSP integration
  { import = "lazyvim.plugins.extras.lang.go" },

  -- Configure Mason to ensure required Go tools are installed
  {
    "williamboman/mason.nvim",
    opts = {
      ensure_installed = {
        "gopls",           -- Go Language Server
        "delve",           -- Go debugger
        "golangci-lint",   -- Go linter
        "goimports",       -- Go import formatter
        "gofumpt",         -- Stricter gofmt
        "gomodifytags",    -- Modify struct tags
        "impl",            -- Generate method stubs for interfaces
        "gotests",         -- Generate Go tests
      },
    },
  },

  -- Configure nvim-lspconfig for Go with optimized settings
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        gopls = {
          settings = {
            gopls = {
              -- Performance optimizations
              completionBudget = "200ms",
              matcher = "Fuzzy",
              completeFunctionCalls = true,
              
              -- Formatting settings
              gofumpt = true,
              local = "", -- Set to your organization prefix, e.g., "github.com/myorg"
              
              -- Enable semantic tokens for better syntax highlighting
              semanticTokens = true,
              
              -- Code lenses configuration
              codelenses = {
                gc_details = false,
                generate = true,
                regenerate_cgo = true,
                tidy = true,
                upgrade_dependency = true,
                vendor = true,
              },
              
              -- Analyses configuration
              analyses = {
                nilness = true,
                unusedparams = true,
                unusedwrite = true,
                useany = true,
                shadow = true,
                unreachable = true,
                ST1003 = true,
                undeclaredname = true,
                fillreturns = true,
                nonewvars = true,
              },
              
              -- Enable staticcheck for additional linting
              staticcheck = true,
              
              -- Hints configuration (for generics and type parameters)
              hints = {
                assignVariableTypes = true,
                compositeLiteralFields = true,
                compositeLiteralTypes = true,
                constantValues = true,
                functionTypeParameters = true,
                parameterNames = true,
                rangeVariableTypes = true,
              },
              
              -- Directory filters for performance
              directoryFilters = {
                "-.git",
                "-.vscode",
                "-.idea",
                "-.vscode-test",
                "-node_modules",
                "-vendor",
              },
              
              -- Experimental features
              experimentalPostfixCompletions = true,
              experimentalUseInvalidMetadata = true,
            },
          },
        },
      },
      setup = {
        gopls = function(_, opts)
          -- Custom on_attach for Go-specific keymaps
          local on_attach = function(client, bufnr)
            -- Enable format on save
            if client.server_capabilities.documentFormattingProvider then
              vim.api.nvim_create_autocmd("BufWritePre", {
                group = vim.api.nvim_create_augroup("GoFormat", { clear = true }),
                buffer = bufnr,
                callback = function()
                  vim.lsp.buf.format({ async = false })
                end,
              })
            end
            
            -- Go-specific keymaps
            local function map(mode, lhs, rhs, desc)
              vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
            end
            
            map("n", "<leader>cR", "<cmd>GoRun<cr>", "Run Go file")
            map("n", "<leader>ct", "<cmd>GoTest<cr>", "Run Go tests")
            map("n", "<leader>cT", "<cmd>GoTestFunc<cr>", "Run Go test function")
            map("n", "<leader>cc", "<cmd>GoCoverage<cr>", "Show Go coverage")
            map("n", "<leader>cf", "<cmd>GoFillStruct<cr>", "Fill Go struct")
            map("n", "<leader>ci", "<cmd>GoImplement<cr>", "Implement interface")
            map("n", "<leader>cj", "<cmd>GoTagAdd<cr>", "Add struct tags")
            map("n", "<leader>ck", "<cmd>GoTagRm<cr>", "Remove struct tags")
          end
          
          LazyVim.lsp.on_attach(on_attach, "gopls")
        end,
      },
    },
  },

  -- Configure conform.nvim for Go formatting
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      formatters_by_ft = {
        go = { "goimports", "gofumpt" },
      },
      formatters = {
        goimports = {
          prepend_args = { "-local", "" }, -- Set your local import prefix here
        },
      },
    },
  },

  -- Configure nvim-lint for Go linting
  {
    "mfussenegger/nvim-lint",
    optional = true,
    opts = {
      linters_by_ft = {
        go = { "golangcilint" },
      },
    },
  },

  -- Enhanced Go development plugin
  {
    "ray-x/go.nvim",
    dependencies = {
      "ray-x/guihua.lua",
      "neovim/nvim-lspconfig",
      "nvim-treesitter/nvim-treesitter",
    },
    config = function()
      require("go").setup({
        -- Disable default LSP config since we configure it above
        lsp_cfg = false,
        
        -- Lsp config
        lsp_keymaps = false, -- We set custom keymaps above
        
        -- Formatting
        lsp_gofumpt = true,
        lsp_on_attach = false, -- We handle this in lspconfig
        
        -- Diagnostics
        lsp_diag_hdlr = true,
        lsp_diag_virtual_text = { space = 0, prefix = "■" },
        lsp_diag_signs = true,
        lsp_diag_update_in_insert = false,
        
        -- Code actions
        lsp_code_action = {
          enable = true,
          sign = true,
          sign_priority = 40,
          virtual_text = true,
        },
        
        -- Inlay hints
        lsp_inlay_hints = {
          enable = true,
          only_current_line = false,
        },
        
        -- Document symbols
        lsp_document_formatting = false, -- Handled by conform.nvim
        
        -- Go tools
        go = "go",
        goimports = "goimports",
        gofmt = "gofumpt",
        
        -- Test configuration
        test_runner = "go",
        run_in_floaterm = false,
        
        -- Coverage
        coverage = {
          sign = "▎",
          sign_covered = "▎",
        },
        
        -- Trouble integration
        trouble = true,
        
        -- Icons
        icons = { breakpoint = "🔴", currentpos = "▶" },
        
        -- Verbose output
        verbose = false,
      })
    end,
    event = { "CmdlineEnter" },
    ft = { "go", "gomod" },
    build = ':lua require("go.install").update_all_sync()'
  },

  -- DAP configuration for Go debugging
  {
    "leoluz/nvim-dap-go",
    dependencies = {
      "mfussenegger/nvim-dap",
      "rcarriga/nvim-dap-ui",
    },
    ft = "go",
    config = function()
      require("dap-go").setup({
        delve = {
          -- Path to delve executable (Mason installs it here)
          path = vim.fn.stdpath("data") .. "/mason/bin/dlv",
          initialize_timeout_sec = 20,
          port = "${port}",
          args = {},
          build_flags = "",
          detached = vim.fn.has("win32") == 0,
        },
        dap_configurations = {
          {
            type = "go",
            name = "Debug",
            request = "launch",
            program = "${file}",
          },
          {
            type = "go",
            name = "Debug test",
            request = "launch",
            mode = "test",
            program = "${file}",
          },
          {
            type = "go",
            name = "Debug test (go.mod)",
            request = "launch",
            mode = "test",
            program = "./${relativeFileDirname}",
          },
          {
            type = "go",
            name = "Attach remote",
            mode = "remote",
            request = "attach",
          },
        },
      })
    end,
    keys = {
      { "<leader>dt", function() require("dap-go").debug_test() end, desc = "Debug Go Test" },
      { "<leader>dT", function() require("dap-go").debug_last_test() end, desc = "Debug Last Go Test" },
    },
  },

  -- Testing with neotest
  {
    "nvim-neotest/neotest",
    dependencies = {
      "nvim-neotest/neotest-go",
    },
    opts = {
      adapters = {
        ["neotest-go"] = {
          experimental = {
            test_table = true,
          },
          args = { "-count=1", "-timeout=60s" },
        },
      },
    },
  },

  -- Treesitter configuration for Go
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = { 
        "go", 
        "gomod", 
        "gowork", 
        "gosum",
      },
    },
  },

  -- Additional Go-related plugins

  -- Struct tag modification
  {
    "fatih/vim-go",
    enabled = false, -- We use go.nvim instead, but keep this as reference
  },

  -- Go template syntax highlighting
  {
    "sebdah/vim-delve",
    enabled = false, -- We use nvim-dap-go instead
  },

  -- Additional text objects for Go
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    optional = true,
    opts = {
      textobjects = {
        select = {
          keymaps = {
            ["af"] = "@function.outer",
            ["if"] = "@function.inner",
            ["am"] = "@call.outer",
            ["im"] = "@call.inner",
            ["as"] = "@struct.outer",
            ["is"] = "@struct.inner",
          },
        },
        move = {
          goto_next_start = {
            ["]f"] = "@function.outer",
            ["]m"] = "@call.outer",
            ["]s"] = "@struct.outer",
          },
          goto_previous_start = {
            ["[f"] = "@function.outer",
            ["[m"] = "@call.outer",
            ["[s"] = "@struct.outer",
          },
        },
      },
    },
  },

  -- Better fold expression for Go
  {
    "kevinhwang91/nvim-ufo",
    optional = true,
    opts = {
      filetype_providers = {
        go = "lsp",
      },
    },
  },
}