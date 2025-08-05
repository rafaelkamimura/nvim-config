-- Enhanced TypeScript/JavaScript Development Environment
-- Based on latest LazyVim patterns and modern tooling
return {
  -- Enable TypeScript extra with modern vtsls
  {
    "LazyVim/LazyVim",
    opts = {
      -- Ensure TypeScript extra is loaded
      extras = {
        "lazyvim.plugins.extras.lang.typescript",
      },
    },
  },

  -- Enhanced nvim-lspconfig for TypeScript/JavaScript
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        -- Disable legacy tsserver in favor of vtsls
        tsserver = { enabled = false },
        ts_ls = { enabled = false },
        
        -- Modern TypeScript Language Server (vtsls)
        vtsls = {
          -- Add all relevant filetypes
          filetypes = {
            "javascript",
            "javascriptreact", 
            "javascript.jsx",
            "typescript",
            "typescriptreact",
            "typescript.tsx",
            "vue",
          },
          settings = {
            complete_function_calls = true,
            vtsls = {
              enableMoveToFileCodeAction = true,
              autoUseWorkspaceTsdk = true,
              experimental = {
                maxInlayHintLength = 30,
                completion = {
                  enableServerSideFuzzyMatch = true,
                },
              },
            },
            typescript = {
              updateImportsOnFileMove = { enabled = "always" },
              suggest = {
                completeFunctionCalls = true,
              },
              inlayHints = {
                enumMemberValues = { enabled = true },
                functionLikeReturnTypes = { enabled = true },
                parameterNames = { enabled = "literals" },
                parameterTypes = { enabled = true },
                propertyDeclarationTypes = { enabled = true },
                variableTypes = { enabled = false }, -- Less noisy
              },
            },
            javascript = {
              updateImportsOnFileMove = { enabled = "always" },
              suggest = {
                completeFunctionCalls = true,
              },
              inlayHints = {
                enumMemberValues = { enabled = true },
                functionLikeReturnTypes = { enabled = true },
                parameterNames = { enabled = "literals" },
                parameterTypes = { enabled = true },
                propertyDeclarationTypes = { enabled = true },
                variableTypes = { enabled = false },
              },
            },
          },
          -- Enhanced keymaps for TypeScript features
          keys = {
            {
              "gD",
              function()
                local params = vim.lsp.util.make_position_params()
                LazyVim.lsp.execute({
                  command = "typescript.goToSourceDefinition",
                  arguments = { params.textDocument.uri, params.position },
                  open = true,
                })
              end,
              desc = "Goto Source Definition",
            },
            {
              "gR",
              function()
                LazyVim.lsp.execute({
                  command = "typescript.findAllFileReferences",
                  arguments = { vim.uri_from_bufnr(0) },
                  open = true,
                })
              end,
              desc = "File References",
            },
            {
              "<leader>co",
              LazyVim.lsp.action["source.organizeImports"],
              desc = "Organize Imports",
            },
            {
              "<leader>cM",
              LazyVim.lsp.action["source.addMissingImports.ts"],
              desc = "Add missing imports",
            },
            {
              "<leader>cu",
              LazyVim.lsp.action["source.removeUnused.ts"],
              desc = "Remove unused imports",
            },
            {
              "<leader>cD",
              LazyVim.lsp.action["source.fixAll.ts"],
              desc = "Fix all diagnostics",
            },
            {
              "<leader>cV",
              function()
                LazyVim.lsp.execute({ command = "typescript.selectTypeScriptVersion" })
              end,
              desc = "Select TS workspace version",
            },
          },
        },

        -- ESLint LSP for linting and formatting
        eslint = {
          settings = {
            -- Support for flat config
            experimental = {
              useFlatConfig = true,
            },
            workingDirectories = { mode = "auto" },
            format = { enable = true },
            validate = "on",
            packageManager = "npm",
            codeActionOnSave = {
              enable = true,
              mode = "problems",
            },
          },
          root_dir = function(fname)
            return require("lspconfig.util").root_pattern(
              "eslint.config.js",
              "eslint.config.mjs", 
              "eslint.config.cjs",
              "eslint.config.ts",
              ".eslintrc.js",
              ".eslintrc.cjs",
              ".eslintrc.yaml",
              ".eslintrc.yml",
              ".eslintrc.json",
              "package.json"
            )(fname)
          end,
        },

        -- JSON Language Server with schema support
        jsonls = {
          settings = {
            json = {
              schemas = require("schemastore").json.schemas(),
              validate = { enable = true },
            },
          },
        },

        -- HTML Language Server
        html = {
          filetypes = { "html", "templ", "astro" },
        },

        -- CSS Language Server
        cssls = {
          settings = {
            css = {
              validate = true,
              lint = {
                unknownAtRules = "ignore",
              },
            },
            scss = {
              validate = true,
              lint = {
                unknownAtRules = "ignore",
              },
            },
            less = {
              validate = true,
              lint = {
                unknownAtRules = "ignore",
              },
            },
          },
        },

        -- Tailwind CSS Language Server
        tailwindcss = {
          root_dir = function(fname)
            return require("lspconfig.util").root_pattern(
              "tailwind.config.js",
              "tailwind.config.cjs",
              "tailwind.config.mjs",
              "tailwind.config.ts",
              "postcss.config.js",
              "postcss.config.cjs",
              "postcss.config.mjs",
              "postcss.config.ts"
            )(fname)
          end,
        },
      },
    },
  },

  -- nvim-vtsls for enhanced TypeScript support
  {
    "yioneko/nvim-vtsls",
    lazy = true,
    opts = {},
    config = function(_, opts)
      require("vtsls").config(opts)
    end,
  },

  -- Enhanced Treesitter configuration
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      if type(opts.ensure_installed) == "table" then
        vim.list_extend(opts.ensure_installed, {
          "typescript",
          "tsx",
          "javascript",
          "jsdoc",
          "json",
          "json5",
          "jsonc",
          "html",
          "css",
          "scss",
          "vue",
          "astro",
          "svelte",
        })
      end
    end,
  },

  -- Enhanced Mason tool installer
  {
    "williamboman/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, {
        -- Language Servers
        "vtsls",
        "eslint-lsp",
        "json-lsp",
        "html-lsp",
        "css-lsp",
        "tailwindcss-language-server",
        
        -- Formatters
        "prettier",
        "prettierd",
        "eslint_d",
        
        -- Linters
        "eslint_d",
        
        -- Debuggers
        "js-debug-adapter",
        
        -- Testing
        "jest",
      })
    end,
  },

  -- Better formatting with conform.nvim
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      formatters_by_ft = {
        ["javascript"] = { "prettierd", "prettier", stop_after_first = true },
        ["javascriptreact"] = { "prettierd", "prettier", stop_after_first = true },
        ["typescript"] = { "prettierd", "prettier", stop_after_first = true },
        ["typescriptreact"] = { "prettierd", "prettier", stop_after_first = true },
        ["vue"] = { "prettierd", "prettier", stop_after_first = true },
        ["css"] = { "prettierd", "prettier", stop_after_first = true },
        ["scss"] = { "prettierd", "prettier", stop_after_first = true },
        ["less"] = { "prettierd", "prettier", stop_after_first = true },
        ["html"] = { "prettierd", "prettier", stop_after_first = true },
        ["json"] = { "prettierd", "prettier", stop_after_first = true },
        ["jsonc"] = { "prettierd", "prettier", stop_after_first = true },
        ["yaml"] = { "prettierd", "prettier", stop_after_first = true },
        ["markdown"] = { "prettierd", "prettier", stop_after_first = true },
        ["markdown.mdx"] = { "prettierd", "prettier", stop_after_first = true },
        ["graphql"] = { "prettierd", "prettier", stop_after_first = true },
        ["handlebars"] = { "prettier" },
      },
      formatters = {
        prettier = {
          condition = function(_, ctx)
            return vim.fs.find(
              { ".prettierrc", ".prettierrc.json", ".prettierrc.yml", ".prettierrc.yaml", ".prettierrc.js", ".prettierrc.mjs", "prettier.config.js", "prettier.config.mjs" },
              { path = ctx.filename, upward = true }
            )[1]
          end,
        },
        prettierd = {
          condition = function(_, ctx)
            return vim.fs.find(
              { ".prettierrc", ".prettierrc.json", ".prettierrc.yml", ".prettierrc.yaml", ".prettierrc.js", ".prettierrc.mjs", "prettier.config.js", "prettier.config.mjs" },
              { path = ctx.filename, upward = true }
            )[1]
          end,
        },
      },
    },
  },

  -- Enhanced linting with nvim-lint
  {
    "mfussenegger/nvim-lint",
    optional = true,
    opts = {
      linters_by_ft = {
        javascript = { "eslint_d" },
        javascriptreact = { "eslint_d" },
        typescript = { "eslint_d" },
        typescriptreact = { "eslint_d" },
        vue = { "eslint_d" },
        svelte = { "eslint_d" },
      },
    },
  },

  -- Package info for package.json
  {
    "vuki656/package-info.nvim",
    dependencies = { "MunifTanjim/nui.nvim" },
    opts = {},
    event = { "BufRead package.json" },
    keys = {
      { "<leader>ns", "<cmd>lua require('package-info').show()<cr>", desc = "Show package info" },
      { "<leader>nc", "<cmd>lua require('package-info').hide()<cr>", desc = "Hide package info" },
      { "<leader>nt", "<cmd>lua require('package-info').toggle()<cr>", desc = "Toggle package info" },
      { "<leader>nu", "<cmd>lua require('package-info').update()<cr>", desc = "Update package" },
      { "<leader>nd", "<cmd>lua require('package-info').delete()<cr>", desc = "Delete package" },
      { "<leader>ni", "<cmd>lua require('package-info').install()<cr>", desc = "Install package" },
      { "<leader>np", "<cmd>lua require('package-info').change_version()<cr>", desc = "Change package version" },
    },
  },

  -- TypeScript error translations
  {
    "dmmulroy/ts-error-translator.nvim",
    opts = {},
    ft = { "typescript", "vue", "typescriptreact" },
  },

  -- Auto-close and rename HTML/JSX tags
  {
    "windwp/nvim-ts-autotag",
    event = "LazyFile",
    opts = {
      opts = {
        enable_close = true,
        enable_rename = true,
        enable_close_on_slash = false,
      },
      per_filetype = {
        ["html"] = { enable_close = false },
        ["javascript"] = { enable_close = false },
        ["typescript"] = { enable_close = false },
        ["javascriptreact"] = { enable_close = true },
        ["typescriptreact"] = { enable_close = true },
        ["vue"] = { enable_close = true },
        ["astro"] = { enable_close = true },
        ["svelte"] = { enable_close = true },
      },
    },
  },

  -- Enhanced auto-pairs for TypeScript
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    opts = {
      check_ts = true,
      ts_config = {
        lua = { "string" },
        javascript = { "template_string" },
        typescript = { "template_string" },
      },
    },
  },

  -- JSON Schema support
  {
    "b0o/schemastore.nvim",
    lazy = true,
    version = false, -- last release is way too old
  },
}