-- Comprehensive Testing Configuration for JavaScript/TypeScript
-- Supports Jest, Vitest, Playwright with Neotest integration
return {
  -- Neotest: Modern testing framework for Neovim
  {
    "nvim-neotest/neotest",
    dependencies = {
      "nvim-neotest/nvim-nio",
      "nvim-lua/plenary.nvim",
      "antoinemadec/FixCursorHold.nvim",
      "nvim-treesitter/nvim-treesitter",
      -- JavaScript/TypeScript adapters
      "nvim-neotest/neotest-jest",
      "marilari88/neotest-vitest",
      "nvim-neotest/neotest-playwright",
    },
    opts = {
      -- Configure adapters for different testing frameworks
      adapters = {
        -- Jest adapter configuration
        ["neotest-jest"] = {
          jestCommand = function(path)
            local file = vim.fn.expand("%:p")
            if string.find(file, "/packages/") then
              -- Monorepo support
              return "cd " .. vim.fn.getcwd() .. " && npm test --silent --testPathPattern=" .. path .. " --"
            end
            return "npm test --silent --testPathPattern=" .. path .. " --"
          end,
          jestConfigFile = function(file)
            local root = vim.fn.getcwd()
            -- Look for various Jest config files
            local possible_configs = {
              "jest.config.js",
              "jest.config.ts",
              "jest.config.mjs",
              "jest.config.json",
              "package.json", -- if jest config is in package.json
            }
            
            for _, config in ipairs(possible_configs) do
              if vim.fn.filereadable(root .. "/" .. config) == 1 then
                return root .. "/" .. config
              end
            end
            
            return nil
          end,
          env = { CI = true },
          cwd = function(path)
            return vim.fn.getcwd()
          end,
        },
        
        -- Vitest adapter configuration
        ["neotest-vitest"] = {
          filter_dir = function(name, rel_path, root)
            return name ~= "node_modules"
          end,
          vitestCommand = "npx vitest",
          vitestConfigFile = function(file)
            local root = vim.fn.getcwd()
            local possible_configs = {
              "vitest.config.ts",
              "vitest.config.js",
              "vitest.config.mjs",
              "vite.config.ts",
              "vite.config.js",
              "vite.config.mjs",
            }
            
            for _, config in ipairs(possible_configs) do
              if vim.fn.filereadable(root .. "/" .. config) == 1 then
                return root .. "/" .. config
              end
            end
            
            return nil
          end,
          env = { CI = true },
          cwd = function(path)
            return vim.fn.getcwd()
          end,
        },
        
        -- Playwright adapter configuration
        ["neotest-playwright"] = {
          options = {
            persist_project_selection = true,
            enable_dynamic_test_discovery = true,
            preset = "none", -- "none" | "headed" | "debug"
          },
        },
      },
      
      -- Global configuration
      discovery = {
        enabled = true,
        concurrent = 1,
      },
      
      diagnostic = {
        enabled = true,
        severity = vim.diagnostic.severity.ERROR,
      },
      
      floating = {
        border = "rounded",
        max_height = 0.6,
        max_width = 0.6,
        options = {},
      },
      
      highlights = {
        adapter_name = "NeotestAdapterName",
        border = "NeotestBorder",
        dir = "NeotestDir",
        expand_marker = "NeotestExpandMarker",
        failed = "NeotestFailed",
        file = "NeotestFile",
        focused = "NeotestFocused",
        indent = "NeotestIndent",
        marked = "NeotestMarked",
        namespace = "NeotestNamespace",
        passed = "NeotestPassed",
        running = "NeotestRunning",
        select_win = "NeotestWinSelect",
        skipped = "NeotestSkipped",
        target = "NeotestTarget",
        test = "NeotestTest",
        unknown = "NeotestUnknown",
      },
      
      icons = {
        child_indent = "│",
        child_prefix = "├",
        collapsed = "─",
        expanded = "╮",
        failed = "✖",
        final_child_indent = " ",
        final_child_prefix = "╰",
        non_collapsible = "─",
        passed = "✓",
        running = "⟳",
        running_animated = { "/", "|", "\\", "-", "/", "|", "\\", "-" },
        skipped = "○",
        unknown = "?",
        watching = "👁",
      },
      
      output = {
        enabled = true,
        open_on_run = "short",
      },
      
      output_panel = {
        enabled = true,
        open = "botright split | resize 15",
      },
      
      quickfix = {
        enabled = true,
        open = false,
      },
      
      run = {
        enabled = true,
      },
      
      state = {
        enabled = true,
      },
      
      status = {
        enabled = true,
        signs = true,
        virtual_text = false,
      },
      
      strategies = {
        integrated = {
          height = 40,
          width = 120,
        },
      },
      
      summary = {
        enabled = true,
        animated = true,
        follow = true,
        expand_errors = true,
        mappings = {
          attach = "a",
          clear_marked = "M",
          clear_target = "T",
          debug = "d",
          debug_marked = "D",
          expand = { "<CR>", "<2-LeftMouse>" },
          expand_all = "e",
          help = "?",
          jumpto = "i",
          mark = "m",
          next_failed = "J",
          output = "o",
          prev_failed = "K",
          run = "r",
          run_marked = "R",
          short = "O",
          stop = "u",
          target = "t",
          watch = "w",
        },
        open = "botright vsplit | vertical resize 50",
      },
    },
    
    config = function(_, opts)
      -- Get neotest namespace (api call creates or returns namespace)
      local neotest_ns = vim.api.nvim_create_namespace("neotest")
      vim.diagnostic.config({
        virtual_text = {
          format = function(diagnostic)
            local message = diagnostic.message:gsub("\n", " "):gsub("\t", " "):gsub("%s+", " "):gsub("^%s+", "")
            return message
          end,
        },
      }, neotest_ns)
      
      require("neotest").setup(opts)
    end,
    
    keys = {
      -- Test runner keymaps
      {
        "<leader>tr",
        function()
          require("neotest").run.run()
        end,
        desc = "Run nearest test",
      },
      {
        "<leader>tR", 
        function()
          require("neotest").run.run(vim.fn.expand("%"))
        end,
        desc = "Run current file tests",
      },
      {
        "<leader>ta",
        function()
          require("neotest").run.run({ suite = true })
        end,
        desc = "Run all tests",
      },
      {
        "<leader>td",
        function()
          require("neotest").run.run({ strategy = "dap" })
        end,
        desc = "Debug nearest test",
      },
      {
        "<leader>tD",
        function()
          require("neotest").run.run({ vim.fn.expand("%"), strategy = "dap" })
        end,
        desc = "Debug current file tests",
      },
      {
        "<leader>ts",
        function()
          require("neotest").summary.toggle()
        end,
        desc = "Toggle test summary",
      },
      {
        "<leader>to",
        function()
          require("neotest").output.open({ enter = true, auto_close = true })
        end,
        desc = "Show test output",
      },
      {
        "<leader>tO",
        function()
          require("neotest").output_panel.toggle()
        end,
        desc = "Toggle test output panel",
      },
      {
        "<leader>tw",
        function()
          require("neotest").watch.toggle()
        end,
        desc = "Toggle test watch mode",
      },
      {
        "<leader>tW",
        function()
          require("neotest").watch.toggle(vim.fn.expand("%"))
        end,
        desc = "Toggle watch current file",
      },
      {
        "<leader>tl",
        function()
          require("neotest").run.run_last()
        end,
        desc = "Run last test",
      },
      {
        "<leader>tL",
        function()
          require("neotest").run.run_last({ strategy = "dap" })
        end,
        desc = "Debug last test",
      },
      -- Test navigation
      {
        "]t",
        function()
          require("neotest").jump.next({ status = "failed" })
        end,
        desc = "Next failed test",
      },
      {
        "[t",
        function()
          require("neotest").jump.prev({ status = "failed" })
        end,
        desc = "Previous failed test",
      },
    },
  },

  -- Coverage display
  {
    "andythigpen/nvim-coverage",
    dependencies = { "nvim-lua/plenary.nvim" },
    cmd = {
      "Coverage",
      "CoverageLoad",
      "CoverageShow",
      "CoverageHide",
      "CoverageToggle",
      "CoverageClear",
    },
    opts = {
      commands = true,
      highlights = {
        covered = { fg = "#C3E88D" },      -- green
        uncovered = { fg = "#F07178" },    -- red
      },
      signs = {
        covered = { hl = "CoverageCovered", text = "▎" },
        uncovered = { hl = "CoverageUncovered", text = "▎" },
      },
      summary = {
        min_coverage = 80.0, -- minimum coverage threshold (percentage)
      },
      lang = {
        javascript = {
          coverage_file = "coverage/lcov.info",
        },
        typescript = {
          coverage_file = "coverage/lcov.info",
        },
      },
    },
    keys = {
      {
        "<leader>tc",
        function()
          require("coverage").load()
          require("coverage").show()
        end,
        desc = "Show test coverage",
      },
      {
        "<leader>tC",
        function()
          require("coverage").hide()
        end,
        desc = "Hide test coverage",
      },
    },
  },

  -- Enhanced test runner with overseer (alternative approach)
  {
    "stevearc/overseer.nvim",
    cmd = {
      "OverseerRun",
      "OverseerToggle",
      "OverseerQuickAction",
      "OverseerTaskAction",
    },
    opts = {
      templates = {
        "builtin",
        "user.npm_test",
        "user.jest_single",
        "user.vitest_single",
      },
      strategy = {
        "terminal",
        use_shell = false,
      },
      auto_scroll = "smart",
      task_list = {
        direction = "bottom",
        min_height = 25,
        max_height = 25,
        default_detail = 1,
        bindings = {
          ["?"] = "ShowHelp",
          ["g?"] = "ShowHelp",
          ["<CR>"] = "RunAction",
          ["<C-e>"] = "Edit",
          ["o"] = "Open",
          ["<C-v>"] = "OpenVsplit",
          ["<C-s>"] = "OpenSplit",
          ["<C-f>"] = "OpenFloat",
          ["<C-q>"] = "OpenQuickFix",
          ["p"] = "TogglePreview",
          ["<C-l>"] = "IncreaseDetail",
          ["<C-h>"] = "DecreaseDetail",
          ["L"] = "IncreaseAllDetail",
          ["H"] = "DecreaseAllDetail",
          ["["] = "DecreaseWidth",
          ["]"] = "IncreaseWidth",
          ["{"] = "PrevTask",
          ["}"] = "NextTask",
          ["<C-k>"] = "ScrollOutputUp",
          ["<C-j>"] = "ScrollOutputDown",
          ["q"] = "Close",
        },
      },
    },
    keys = {
      {
        "<leader>oo",
        "<cmd>OverseerToggle<cr>",
        desc = "Toggle Overseer",
      },
      {
        "<leader>or",
        "<cmd>OverseerRun<cr>",
        desc = "Run Overseer task",
      },
    },
  },

  -- Mason tool installer for testing tools
  {
    "williamboman/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, {
        "jest",
        "playwright",
      })
    end,
  },
}