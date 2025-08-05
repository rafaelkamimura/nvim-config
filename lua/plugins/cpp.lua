-- Comprehensive C++ development configuration for LazyVim
-- Supports modern C++17/20/23 features, clangd, debugging, and build systems

return {
  -- Add C++ language support to LazyVim
  { import = "lazyvim.plugins.extras.lang.clangd" },

  -- Enhanced clangd configuration
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        clangd = {
          cmd = {
            "clangd",
            "--background-index",
            "--clang-tidy",
            "--header-insertion=iwyu",
            "--completion-style=detailed",
            "--function-arg-placeholders",
            "--fallback-style=llvm",
            "--limit-results=200",
            "--limit-references=500",
            "--query-driver=" .. (vim.fn.executable("/opt/homebrew/opt/llvm/bin/clang++") == 1
              and "/opt/homebrew/opt/llvm/bin/clang++"
              or "/usr/bin/clang++"),
            "--enable-config",
            "-j=8",
            "--pch-storage=memory",
            "--malloc-trim",
            "--log=error",
          },
          init_options = {
            usePlaceholders = true,
            completeUnimported = true,
            clangdFileStatus = true,
          },
          filetypes = { "c", "cpp", "objc", "objcpp", "cuda", "proto" },
          root_dir = function(fname)
            return require("lspconfig.util").root_pattern(
              "Makefile",
              "configure.in",
              "configure.ac",
              ".git",
              "compile_commands.json",
              "compile_flags.txt",
              "CMakeLists.txt",
              "build.ninja",
              ".clangd",
              ".clang-format"
            )(fname)
          end,
          single_file_support = true,
        },
      },
    },
  },

  -- clangd extensions for enhanced features
  {
    "p00f/clangd_extensions.nvim",
    lazy = true,
    config = function()
      require("clangd_extensions").setup({
        server = {},
        extensions = {
          -- Enable automatic header/source file switching
          autoSetHints = true,
          hover_with_actions = true,
          -- Enable inlay hints
          inlay_hints = {
            inline = vim.fn.has("nvim-0.10") == 1,
            only_current_line = false,
            only_current_line_autocmd = { "CursorHold", "CursorHoldI" },
            show_parameter_hints = true,
            show_variable_name = false,
            parameter_hints_prefix = "<- ",
            other_hints_prefix = "=> ",
            max_len_align = false,
            max_len_align_padding = 1,
            right_align = false,
            right_align_padding = 7,
            highlight = "Comment",
            priority = 100,
          },
          ast = {
            role_icons = {
              type = "",
              declaration = "",
              expression = "",
              specifier = "",
              statement = "",
              ["template argument"] = "",
            },
            kind_icons = {
              Compound = "",
              Recovery = "",
              TranslationUnit = "",
              PackExpansion = "",
              TemplateTypeParm = "",
              TemplateTemplateParm = "",
              TemplateParamObject = "",
            },
            highlights = {
              detail = "Comment",
            },
          },
          memory_usage = {
            border = "none",
          },
          symbol_info = {
            border = "none",
          },
        },
      })
    end,
  },

  -- Enhanced treesitter configuration for C++
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      -- Ensure C++ parsers are installed
      vim.list_extend(opts.ensure_installed, {
        "c",
        "cpp",
        "cmake",
        "make",
        "ninja",
        "cuda",
        "proto",
      })

      -- Enhanced C++ highlighting
      if type(opts.highlight) == "table" then
        opts.highlight.additional_vim_regex_highlighting = { "cpp" }
      end

      -- Enable better C++ indentation
      if type(opts.indent) == "table" then
        opts.indent.enable = true
      end

      -- Enable text objects for C++
      if type(opts.textobjects) == "table" then
        opts.textobjects.select = vim.tbl_deep_extend("force", opts.textobjects.select or {}, {
          enable = true,
          lookahead = true,
          keymaps = {
            ["af"] = "@function.outer",
            ["if"] = "@function.inner",
            ["ac"] = "@class.outer",
            ["ic"] = "@class.inner",
            ["al"] = "@loop.outer",
            ["il"] = "@loop.inner",
            ["aa"] = "@parameter.outer",
            ["ia"] = "@parameter.inner",
          },
        })
      end
    end,
  },

  -- DAP configuration for C++ debugging
  {
    "mfussenegger/nvim-dap",
    optional = true,
    dependencies = {
      {
        "williamboman/mason.nvim",
        opts = function(_, opts)
          opts.ensure_installed = opts.ensure_installed or {}
          vim.list_extend(opts.ensure_installed, { "codelldb" })
        end,
      },
    },
    opts = function()
      local dap = require("dap")
      local mason_registry = require("mason-registry")
      
      -- LLDB adapter (preferred on macOS)
      dap.adapters.lldb = {
        type = "executable",
        command = function()
          -- Try to find lldb-vscode in common locations
          local possible_paths = {
            vim.fn.exepath("lldb-vscode"),
            "/usr/bin/lldb-vscode",
            "/opt/homebrew/bin/lldb-vscode"
          }
          
          for _, path in ipairs(possible_paths) do
            if path and path ~= "" and vim.fn.executable(path) == 1 then
              return path
            end
          end
          
          -- If not found, return a reasonable default and let it fail gracefully
          return "lldb-vscode"
        end,
        name = "lldb",
      }

      -- CodeLLDB adapter (from mason)
      dap.adapters.codelldb = {
        type = "server",
        port = "${port}",
        executable = {
          command = function()
            -- First try to get codelldb from Mason
            if mason_registry.is_installed("codelldb") then
              return mason_registry.get_package("codelldb"):get_install_path() .. "/codelldb"
            end
            -- Fallback to system path or manual path
            return vim.fn.exepath("codelldb") or vim.fn.expand("~/.local/share/nvim/mason/bin/codelldb")
          end,
          args = { "--port", "${port}" },
        },
      }

      -- GDB adapter (for Linux systems)
      dap.adapters.gdb = {
        type = "executable",
        command = "gdb",
        args = { "--interpreter=dap", "--eval-command", "set print pretty on" },
      }

      -- C++ debug configurations
      for _, lang in ipairs({ "c", "cpp" }) do
        dap.configurations[lang] = {
          {
            name = "Launch file (LLDB)",
            type = "lldb",
            request = "launch",
            program = function()
              return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
            end,
            cwd = "${workspaceFolder}",
            stopOnEntry = false,
            args = {},
            runInTerminal = false,
          },
          {
            name = "Launch file (CodeLLDB)",
            type = "codelldb",
            request = "launch",
            program = function()
              return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
            end,
            cwd = "${workspaceFolder}",
            stopOnEntry = false,
            args = {},
            runInTerminal = false,
          },
          {
            name = "Attach to process (LLDB)",
            type = "lldb",
            request = "attach",
            pid = require("dap.utils").pick_process,
            args = {},
          },
        }
      end
    end,
  },

  -- Code formatting with clang-format
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      formatters_by_ft = {
        c = { "clang_format" },
        cpp = { "clang_format" },
        cuda = { "clang_format" },
      },
      formatters = {
        clang_format = {
          command = "clang-format",
          args = {
            "--style=file",
            "--fallback-style=llvm",
            "--assume-filename",
            "$FILENAME",
          },
        },
      },
    },
  },

  -- Build system integration
  {
    "Civitasv/cmake-tools.nvim",
    cmd = {
      "CMakeGenerate",
      "CMakeBuild",
      "CMakeRun",
      "CMakeDebug",
      "CMakeSelectBuildType",
      "CMakeSelectBuildTarget",
      "CMakeSelectLaunchTarget",
      "CMakeSelectKit",
      "CMakeSelectConfigurePreset",
      "CMakeSelectBuildPreset",
    },
    init = function()
      local loaded = false
      local function check()
        local cwd = vim.uv.cwd()
        if vim.fn.filereadable(cwd .. "/CMakeLists.txt") == 1 then
          require("lazy").load({ plugins = { "cmake-tools.nvim" } })
          loaded = true
        end
      end
      check()
      vim.api.nvim_create_autocmd("DirChanged", {
        callback = function()
          if not loaded then
            check()
          end
        end,
      })
    end,
    opts = {
      cmake_command = "cmake",
      cmake_build_directory = "build/${variant:buildType}",
      cmake_build_directory_prefix = "build/",
      cmake_generate_options = { "-DCMAKE_EXPORT_COMPILE_COMMANDS=1" },
      cmake_build_options = {},
      cmake_console_size = 10,
      cmake_show_console = "always",
      cmake_dap_configuration = {
        name = "Launch file (CMake)",
        type = "codelldb",
        request = "launch",
        stopOnEntry = false,
        runInTerminal = true,
        console = "integratedTerminal",
      },
      cmake_variants_message = {
        short = { show = true },
        long = { show = true, max_length = 40 },
      },
      cmake_dap_open_command = require("dap").repl.open,
    },
  },

  -- Enhanced which-key mappings for C++
  {
    "folke/which-key.nvim",
    optional = true,
    opts = {
      defaults = {
        ["<leader>c"] = { name = "+code" },
        ["<leader>cm"] = { name = "+cmake" },
        ["<leader>cd"] = { name = "+debug" },
      },
    },
  },

  -- Additional keymaps for C++ development
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = function()
        require("tokyonight").load()
      end,
    },
    keys = {
      -- CMake commands
      { "<leader>cmg", "<cmd>CMakeGenerate<cr>", desc = "CMake Generate" },
      { "<leader>cmb", "<cmd>CMakeBuild<cr>", desc = "CMake Build" },
      { "<leader>cmr", "<cmd>CMakeRun<cr>", desc = "CMake Run" },
      { "<leader>cmd", "<cmd>CMakeDebug<cr>", desc = "CMake Debug" },
      { "<leader>cmt", "<cmd>CMakeSelectBuildType<cr>", desc = "CMake Select Build Type" },
      { "<leader>cmT", "<cmd>CMakeSelectBuildTarget<cr>", desc = "CMake Select Build Target" },
      { "<leader>cml", "<cmd>CMakeSelectLaunchTarget<cr>", desc = "CMake Select Launch Target" },
      { "<leader>cmk", "<cmd>CMakeSelectKit<cr>", desc = "CMake Select Kit" },

      -- clangd specific commands
      { "<leader>ch", "<cmd>ClangdSwitchSourceHeader<cr>", desc = "Switch Source/Header" },
      { "<leader>cH", "<cmd>ClangdAST<cr>", desc = "View AST" },
      { "<leader>ci", "<cmd>ClangdSymbolInfo<cr>", desc = "Symbol Info" },
      { "<leader>cm", "<cmd>ClangdMemoryUsage<cr>", desc = "Memory Usage" },

      -- Debug keymaps
      { "<leader>cdb", "<cmd>DapToggleBreakpoint<cr>", desc = "Toggle Breakpoint" },
      { "<leader>cdc", "<cmd>DapContinue<cr>", desc = "Continue" },
      { "<leader>cds", "<cmd>DapStepOver<cr>", desc = "Step Over" },
      { "<leader>cdi", "<cmd>DapStepInto<cr>", desc = "Step Into" },
      { "<leader>cdo", "<cmd>DapStepOut<cr>", desc = "Step Out" },
      { "<leader>cdr", "<cmd>DapRepl<cr>", desc = "Open REPL" },
      { "<leader>cdt", "<cmd>DapTerminate<cr>", desc = "Terminate" },
    },
  },

  -- Mason ensure C++ tools are installed
  {
    "williamboman/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, {
        "clangd",
        "clang-format",
        "codelldb",
        "cmake-language-server",
        "cpptools",
      })
    end,
  },

  -- Update lazyvim.json to include C++ extras
  {
    "folke/lazy.nvim",
    opts = function(_, opts)
      local lazyvim_config_path = vim.fn.stdpath("config") .. "/lazyvim.json"
      local config = {}
      
      if vim.fn.filereadable(lazyvim_config_path) == 1 then
        local file = io.open(lazyvim_config_path, "r")
        if file then
          local content = file:read("*all")
          file:close()
          config = vim.json.decode(content) or {}
        end
      end
      
      config.extras = config.extras or {}
      local cpp_extras = {
        "lazyvim.plugins.extras.lang.clangd",
        "lazyvim.plugins.extras.dap.core",
        "lazyvim.plugins.extras.formatting.conform",
      }
      
      for _, extra in ipairs(cpp_extras) do
        if not vim.tbl_contains(config.extras, extra) then
          table.insert(config.extras, extra)
        end
      end
      
      local file = io.open(lazyvim_config_path, "w")
      if file then
        file:write(vim.json.encode(config))
        file:close()
      end
    end,
  },
}