return {
  -- Import the LazyVim Python extra for proper LSP integration
  { import = "lazyvim.plugins.extras.lang.python" },

  -- Configure Mason to ensure required tools are installed
  {
    "williamboman/mason.nvim",
    opts = {
      ensure_installed = {
        "ruff",        -- Linter and formatter
        "pyright",     -- LSP server
        "black",       -- Alternative formatter (backup)
        "isort",       -- Import sorting (backup)
      },
    },
  },

  -- Configure nvim-lspconfig for Python
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        -- Pyright LSP configuration
        pyright = {
          settings = {
            python = {
              analysis = {
                autoSearchPaths = true,
                useLibraryCodeForTypes = true,
                diagnosticMode = "workspace",
                typeCheckingMode = "basic",
              },
            },
          },
        },
        -- Ruff LSP for fast linting
        ruff = {
          cmd_env = { RUFF_TRACE = "messages" },
          init_options = {
            settings = {
              logLevel = "error",
            },
          },
          keys = {
            {
              "<leader>co",
              LazyVim.lsp.action["source.organizeImports"],
              desc = "Organize Imports",
            },
          },
        },
      },
      setup = {
        ruff = function()
          LazyVim.lsp.on_attach(function(client, _)
            -- Disable hover in favor of Pyright
            client.server_capabilities.hoverProvider = false
          end, "ruff")
        end,
      },
    },
  },

  -- Configure none-ls (null-ls successor) for additional formatting
  {
    "nvimtools/none-ls.nvim",
    optional = true,
    opts = function(_, opts)
      local nls = require("null-ls")
      opts.sources = vim.list_extend(opts.sources or {}, {
        -- Use Ruff for formatting and organizing imports
        nls.builtins.formatting.ruff.with({
          extra_args = {
            "--line-length=120",
            "--select=E,W,F,I",
            "--extend-select=UP",
            "--ignore=E501",
          },
        }),
        nls.builtins.formatting.ruff_format.with({
          extra_args = { "--line-length=120" },
        }),
      })
    end,
  },

  -- Configure conform.nvim for formatting
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      formatters_by_ft = {
        python = { "ruff_format", "ruff_organize_imports" },
      },
      formatters = {
        ruff_format = {
          args = {
            "format",
            "--line-length=120",
            "--stdin-filename",
            "$FILENAME",
            "-",
          },
        },
        ruff_organize_imports = {
          args = {
            "check",
            "--select=I",
            "--fix",
            "--stdin-filename",
            "$FILENAME",
            "-",
          },
        },
      },
    },
  },

  -- Configure nvim-lint for additional linting
  {
    "mfussenegger/nvim-lint",
    optional = true,
    opts = {
      linters_by_ft = {
        python = { "ruff" },
      },
      linters = {
        ruff = {
          args = {
            "check",
            "--line-length=120",
            "--select=E,W,F,I,UP",
            "--ignore=E501",
            "--output-format=json",
            "--stdin-filename",
            function()
              return vim.api.nvim_buf_get_name(0)
            end,
            "-",
          },
        },
      },
    },
  },

  -- Treesitter configuration for Python
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = { "python", "toml" },
    },
  },

  -- DAP configuration for Python debugging
  {
    "mfussenegger/nvim-dap-python",
    dependencies = {
      "mfussenegger/nvim-dap",
      "rcarriga/nvim-dap-ui",
    },
    ft = "python",
    config = function()
      local dap_python = require("dap-python")
      -- Try to find Python executable
      local python_path = vim.fn.exepath("python3") or vim.fn.exepath("python")
      if python_path ~= "" then
        dap_python.setup(python_path)
      end
    end,
  },
}