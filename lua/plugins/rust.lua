return {
  -- rustaceanvim: The modern successor to rust-tools.nvim
  {
    "mrcjkb/rustaceanvim",
    version = "^6", -- Recommended to pin to major version
    lazy = false, -- This plugin is already lazy by default
    ft = { "rust" },
    dependencies = {
      "nvim-lua/plenary.nvim",
      "mfussenegger/nvim-dap",
    },
    config = function()
      vim.g.rustaceanvim = {
        -- Plugin configuration
        tools = {
          -- Automatically set inlay hints (type hints)
          inlay_hints = {
            auto = true,
            show_parameter_hints = true,
            parameter_hints_prefix = "<- ",
            other_hints_prefix = "=> ",
          },
        },
        -- LSP configuration
        server = {
          on_attach = function(client, bufnr)
            -- Set up keymaps for Rust-specific features
            local opts = { buffer = bufnr, silent = true }
            
            -- Code actions
            vim.keymap.set("n", "<leader>cR", function()
              vim.cmd.RustLsp("codeAction")
            end, vim.tbl_extend("force", opts, { desc = "Code Action" }))
            
            -- Rust-specific actions
            vim.keymap.set("n", "<leader>dr", function()
              vim.cmd.RustLsp("debuggables")
            end, vim.tbl_extend("force", opts, { desc = "Rust Debuggables" }))
            
            vim.keymap.set("n", "<leader>rr", function()
              vim.cmd.RustLsp("runnables")
            end, vim.tbl_extend("force", opts, { desc = "Rust Runnables" }))
            
            vim.keymap.set("n", "<leader>rt", function()
              vim.cmd.RustLsp("testables")
            end, vim.tbl_extend("force", opts, { desc = "Rust Testables" }))
            
            vim.keymap.set("n", "<leader>rm", function()
              vim.cmd.RustLsp("expandMacro")
            end, vim.tbl_extend("force", opts, { desc = "Expand Macro" }))
            
            vim.keymap.set("n", "<leader>rc", function()
              vim.cmd.RustLsp("openCargo")
            end, vim.tbl_extend("force", opts, { desc = "Open Cargo.toml" }))
            
            vim.keymap.set("n", "<leader>rp", function()
              vim.cmd.RustLsp("parentModule")
            end, vim.tbl_extend("force", opts, { desc = "Parent Module" }))
            
            vim.keymap.set("n", "<leader>rj", function()
              vim.cmd.RustLsp("joinLines")
            end, vim.tbl_extend("force", opts, { desc = "Join Lines" }))
            
            vim.keymap.set("n", "<leader>rs", function()
              vim.cmd.RustLsp("ssr")
            end, vim.tbl_extend("force", opts, { desc = "Structural Search Replace" }))
            
            vim.keymap.set("n", "<leader>rd", function()
              vim.cmd.RustLsp("renderDiagnostic")
            end, vim.tbl_extend("force", opts, { desc = "Render Diagnostic" }))
            
            vim.keymap.set("n", "<leader>re", function()
              vim.cmd.RustLsp("explainError")
            end, vim.tbl_extend("force", opts, { desc = "Explain Error" }))
            
            vim.keymap.set("n", "<leader>rH", function()
              vim.cmd.RustLsp("hover", "actions")
            end, vim.tbl_extend("force", opts, { desc = "Hover Actions" }))
            
            vim.keymap.set("n", "<leader>rR", function()
              vim.cmd.RustLsp("hover", "range")
            end, vim.tbl_extend("force", opts, { desc = "Hover Range" }))
            
            -- Workspace diagnostics
            vim.keymap.set("n", "<leader>rw", function()
              vim.cmd.RustLsp("workspaceSymbol")
            end, vim.tbl_extend("force", opts, { desc = "Workspace Symbol" }))
            
            -- Enable inlay hints by default for Rust files
            if vim.lsp.inlay_hint and client.supports_method("textDocument/inlayHint") then
              vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
            end
          end,
          
          -- Advanced rust-analyzer configuration
          default_settings = {
            ["rust-analyzer"] = {
              -- Performance optimizations
              cachePriming = {
                enable = true,
                numThreads = 8, -- Adjust based on your CPU cores
              },
              cargo = {
                -- Load all features for better analysis
                allFeatures = true,
                -- Load out directories from check for better support
                loadOutDirsFromCheck = true,
                -- Build scripts configuration
                buildScripts = {
                  enable = true,
                },
                -- Auto reload on Cargo.toml changes
                autoreload = true,
                -- Use rustc wrapper for better integration
                runBuildScripts = true,
                -- Target directory for build artifacts
                targetDir = true,
                -- Unset test for better performance
                unsetTest = { "core" },
              },
              
              -- Check configuration
              checkOnSave = {
                enable = true,
                command = "clippy", -- Use clippy instead of check for better lints
                features = "all",
                extraArgs = {
                  "--",
                  "--warn", "clippy::all",
                  "--warn", "clippy::pedantic",
                  "--warn", "clippy::restriction",
                  "--warn", "clippy::nursery",
                  -- Allow some common false positives
                  "--allow", "clippy::module_name_repetitions",
                  "--allow", "clippy::missing_docs_in_private_items",
                  "--allow", "clippy::implicit_return",
                  "--allow", "clippy::missing_inline_in_public_items",
                },
              },
              
              -- Diagnostics configuration
              diagnostics = {
                enable = true,
                enableExperimental = true,
                disabled = { "unresolved-proc-macro" },
                remapPrefix = {},
                warningsAsHint = {},
                warningsAsInfo = {},
              },
              
              -- Files configuration for better performance
              files = {
                excludeDirs = {
                  ".direnv",
                  ".git",
                  ".github",
                  ".gitlab",
                  "bin",
                  "node_modules",
                  "target",
                  "venv",
                  ".venv",
                  "__pycache__",
                },
                -- Increase file watch limit for large projects
                watcher = "notify",
                watcherExclude = {
                  "**/.git/**",
                  "**/target/**",
                  "**/node_modules/**",
                },
              },
              
              -- Hover configuration
              hover = {
                actions = {
                  enable = true,
                  implementations = true,
                  references = true,
                  run = true,
                  debug = true,
                },
                documentation = {
                  enable = true,
                  keywords = true,
                },
                links = {
                  enable = true,
                },
              },
              
              -- Inlay hints configuration
              inlayHints = {
                bindingModeHints = {
                  enable = true,
                },
                chainingHints = {
                  enable = true,
                },
                closingBraceHints = {
                  enable = true,
                  minLines = 25,
                },
                closureReturnTypeHints = {
                  enable = "with_block",
                },
                discriminantHints = {
                  enable = "fieldless",
                },
                expressionAdjustmentHints = {
                  enable = "reborrow",
                  hideOutsideUnsafe = true,
                  mode = "prefix",
                },
                implicitDrops = {
                  enable = true,
                },
                lifetimeElisionHints = {
                  enable = "skip_trivial",
                  useParameterNames = true,
                },
                maxLength = 25,
                parameterHints = {
                  enable = true,
                },
                reborrowHints = {
                  enable = "mutable",
                },
                renderColons = true,
                typeHints = {
                  enable = true,
                  hideClosureInitialization = false,
                  hideNamedConstructor = false,
                },
              },
              
              -- Lens configuration
              lens = {
                enable = true,
                debug = {
                  enable = true,
                },
                implementations = {
                  enable = true,
                },
                references = {
                  adt = {
                    enable = true,
                  },
                  enumVariant = {
                    enable = true,
                  },
                  method = {
                    enable = true,
                  },
                  trait = {
                    enable = true,
                  },
                },
                run = {
                  enable = true,
                },
              },
              
              -- Macro support
              procMacro = {
                enable = true,
                ignored = {
                  ["async-trait"] = { "async_trait" },
                  ["napi-derive"] = { "napi" },
                  ["async-recursion"] = { "async_recursion" },
                },
                attributes = {
                  enable = true,
                },
              },
              
              -- Semantic highlighting
              semanticHighlighting = {
                strings = {
                  enable = true,
                },
                punctuation = {
                  enable = true,
                  separate = {
                    macro = {
                      bang = true,
                    },
                  },
                  specialization = {
                    enable = true,
                  },
                },
                operator = {
                  enable = true,
                  specialization = {
                    enable = true,
                  },
                },
              },
              
              -- Workspace configuration
              workspace = {
                symbol = {
                  search = {
                    scope = "workspace_and_dependencies",
                    kind = "all_symbols",
                  },
                },
              },
              
              -- Rust-analyzer specific features
              runnables = {
                command = "cargo",
                extraArgs = {},
              },
              
              -- Rustfmt configuration
              rustfmt = {
                extraArgs = {},
                overrideCommand = nil,
                rangeFormatting = {
                  enable = false,
                },
              },
              
              -- Typing assist
              typing = {
                autoClosingAngleBrackets = {
                  enable = true,
                },
              },
            },
          },
        },
        
        -- DAP configuration for debugging
        dap = {
          adapter = {
            type = "executable",
            command = "lldb-vscode", -- or codelldb if installed
            name = "rt_lldb",
          },
        },
      }
    end,
  },

  -- Enhanced crates.nvim configuration for Cargo.toml management
  {
    "saecki/crates.nvim",
    event = { "BufRead Cargo.toml" },
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      require("crates").setup({
        completion = {
          crates = {
            enabled = true,
            max_results = 8,
            min_chars = 3,
          },
          cmp = {
            enabled = true,
          },
        },
        lsp = {
          enabled = true,
          actions = true,
          completion = true,
          hover = true,
        },
        popup = {
          autofocus = true,
          hide_on_select = true,
          copy_register = '"',
          style = "minimal",
          border = "rounded",
          show_version_date = true,
          show_dependency_version = true,
          max_height = 30,
          min_width = 20,
          padding = 1,
        },
        src = {
          insert_closing_quote = true,
          text = {
            prerelease = "  pre-release ",
            yanked = "  yanked ",
          },
        },
        null_ls = {
          enabled = true,
          name = "crates.nvim",
        },
      })
      
      -- Set up keymaps for crates.nvim
      local opts = { silent = true }
      vim.keymap.set("n", "<leader>ct", function()
        require("crates").toggle()
      end, vim.tbl_extend("force", opts, { desc = "Toggle Crates" }))
      
      vim.keymap.set("n", "<leader>cr", function()
        require("crates").reload()
      end, vim.tbl_extend("force", opts, { desc = "Reload Crates" }))
      
      vim.keymap.set("n", "<leader>cv", function()
        require("crates").show_versions_popup()
      end, vim.tbl_extend("force", opts, { desc = "Show Versions" }))
      
      vim.keymap.set("n", "<leader>cf", function()
        require("crates").show_features_popup()
      end, vim.tbl_extend("force", opts, { desc = "Show Features" }))
      
      vim.keymap.set("n", "<leader>cd", function()
        require("crates").show_dependencies_popup()
      end, vim.tbl_extend("force", opts, { desc = "Show Dependencies" }))
      
      vim.keymap.set("n", "<leader>cu", function()
        require("crates").update_crate()
      end, vim.tbl_extend("force", opts, { desc = "Update Crate" }))
      
      vim.keymap.set("v", "<leader>cu", function()
        require("crates").update_crates()
      end, vim.tbl_extend("force", opts, { desc = "Update Crates" }))
      
      vim.keymap.set("n", "<leader>ca", function()
        require("crates").update_all_crates()
      end, vim.tbl_extend("force", opts, { desc = "Update All Crates" }))
      
      vim.keymap.set("n", "<leader>cU", function()
        require("crates").upgrade_crate()
      end, vim.tbl_extend("force", opts, { desc = "Upgrade Crate" }))
      
      vim.keymap.set("v", "<leader>cU", function()
        require("crates").upgrade_crates()
      end, vim.tbl_extend("force", opts, { desc = "Upgrade Crates" }))
      
      vim.keymap.set("n", "<leader>cA", function()
        require("crates").upgrade_all_crates()
      end, vim.tbl_extend("force", opts, { desc = "Upgrade All Crates" }))
      
      vim.keymap.set("n", "<leader>ch", function()
        require("crates").open_homepage()
      end, vim.tbl_extend("force", opts, { desc = "Open Homepage" }))
      
      vim.keymap.set("n", "<leader>cR", function()
        require("crates").open_repository()
      end, vim.tbl_extend("force", opts, { desc = "Open Repository" }))
      
      vim.keymap.set("n", "<leader>cD", function()
        require("crates").open_documentation()
      end, vim.tbl_extend("force", opts, { desc = "Open Documentation" }))
      
      vim.keymap.set("n", "<leader>cC", function()
        require("crates").open_crates_io()
      end, vim.tbl_extend("force", opts, { desc = "Open crates.io" }))
      
      vim.keymap.set("n", "<leader>cl", function()
        require("crates").open_lib_rs()
      end, vim.tbl_extend("force", opts, { desc = "Open lib.rs" }))
    end,
  },

  -- Enhanced treesitter support for Rust
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      -- Ensure rust and ron are installed
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, { "rust", "ron", "toml" })
      
      -- Enhanced syntax highlighting for Rust
      opts.highlight = opts.highlight or {}
      opts.highlight.additional_vim_regex_highlighting = { "rust" }
      
      return opts
    end,
  },

  -- Rust-specific formatters and linters
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      formatters_by_ft = {
        rust = { "rustfmt" },
        toml = { "taplo" },
      },
      formatters = {
        rustfmt = {
          command = "rustfmt",
          args = { "--edition=2021" },
          stdin = true,
        },
      },
    },
  },

  -- Enhanced neotest integration for Rust testing
  {
    "nvim-neotest/neotest",
    optional = true,
    dependencies = {
      "rouge8/neotest-rust",
    },
    opts = {
      adapters = {
        ["neotest-rust"] = {
          args = { "--no-capture" },
          dap_adapter = "codelldb",
        },
      },
    },
  },
}