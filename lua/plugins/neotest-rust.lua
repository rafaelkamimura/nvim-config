return {
  -- Enhanced neotest configuration for Rust testing
  {
    "nvim-neotest/neotest",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
      "antoinemadec/FixCursorHold.nvim",
      "rouge8/neotest-rust",
    },
    config = function()
      local neotest = require("neotest")
      
      neotest.setup({
        adapters = {
          require("neotest-rust")({
            -- Use cargo-nextest for faster test execution
            args = { "--no-capture" },
            -- Use codelldb for debugging tests
            dap_adapter = "codelldb",
          }),
        },
        -- Configure test discovery
        discovery = {
          concurrent = 8, -- Number of workers for test discovery
          enabled = true,
        },
        -- Configure test running
        running = {
          concurrent = true,
        },
        -- Configure test summary
        summary = {
          enabled = true,
          animated = true,
          follow = true,
          expand_errors = true,
          open = "botright vsplit | vertical resize 50",
        },
        -- Configure test output
        output = {
          enabled = true,
          open_on_run = "short",
        },
        -- Configure quickfix
        quickfix = {
          enabled = true,
          open = false,
        },
        -- Configure status signs
        status = {
          enabled = true,
          virtual_text = true,
          signs = true,
        },
        -- Configure icons
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
          running = "🏃",
          running_animated = { "/", "|", "\\", "-", "/", "|", "\\", "-" },
          skipped = "⊝",
          unknown = "?",
        },
        -- Configure floating windows
        floating = {
          border = "rounded",
          max_height = 0.9,
          max_width = 0.9,
          options = {},
        },
        -- Configure strategies
        strategies = {
          integrated = {
            height = 40,
            width = 120,
          },
        },
        -- Configure diagnostic integration
        diagnostic = {
          enabled = true,
          severity = vim.diagnostic.severity.ERROR,
        },
      })
      
      -- Set up keymaps for neotest
      local opts = { silent = true }
      
      -- Test running commands
      vim.keymap.set("n", "<leader>tt", function()
        neotest.run.run()
      end, vim.tbl_extend("force", opts, { desc = "Test: Run Nearest" }))
      
      vim.keymap.set("n", "<leader>tf", function()
        neotest.run.run(vim.fn.expand("%"))
      end, vim.tbl_extend("force", opts, { desc = "Test: Run File" }))
      
      vim.keymap.set("n", "<leader>ta", function()
        neotest.run.run(vim.fn.getcwd())
      end, vim.tbl_extend("force", opts, { desc = "Test: Run All" }))
      
      vim.keymap.set("n", "<leader>tl", function()
        neotest.run.run_last()
      end, vim.tbl_extend("force", opts, { desc = "Test: Run Last" }))
      
      vim.keymap.set("n", "<leader>ts", function()
        neotest.summary.toggle()
      end, vim.tbl_extend("force", opts, { desc = "Test: Toggle Summary" }))
      
      vim.keymap.set("n", "<leader>to", function()
        neotest.output.open({ enter = true, auto_close = true })
      end, vim.tbl_extend("force", opts, { desc = "Test: Show Output" }))
      
      vim.keymap.set("n", "<leader>tO", function()
        neotest.output_panel.toggle()
      end, vim.tbl_extend("force", opts, { desc = "Test: Toggle Output Panel" }))
      
      -- Test debugging commands
      vim.keymap.set("n", "<leader>td", function()
        neotest.run.run({ strategy = "dap" })
      end, vim.tbl_extend("force", opts, { desc = "Test: Debug Nearest" }))
      
      vim.keymap.set("n", "<leader>tD", function()
        neotest.run.run({ vim.fn.expand("%"), strategy = "dap" })
      end, vim.tbl_extend("force", opts, { desc = "Test: Debug File" }))
      
      -- Test navigation commands
      vim.keymap.set("n", "]t", function()
        neotest.jump.next({ status = "failed" })
      end, vim.tbl_extend("force", opts, { desc = "Test: Next Failed" }))
      
      vim.keymap.set("n", "[t", function()
        neotest.jump.prev({ status = "failed" })
      end, vim.tbl_extend("force", opts, { desc = "Test: Previous Failed" }))
      
      -- Test stopping commands
      vim.keymap.set("n", "<leader>tx", function()
        neotest.run.stop()
      end, vim.tbl_extend("force", opts, { desc = "Test: Stop Running" }))
      
      -- Rust-specific test commands
      vim.keymap.set("n", "<leader>tr", function()
        -- Run cargo test with nextest
        vim.cmd("terminal cargo nextest run")
      end, vim.tbl_extend("force", opts, { desc = "Test: Cargo Nextest Run" }))
      
      vim.keymap.set("n", "<leader>tb", function()
        -- Run cargo test in release mode
        vim.cmd("terminal cargo test --release")
      end, vim.tbl_extend("force", opts, { desc = "Test: Cargo Test Release" }))
      
      vim.keymap.set("n", "<leader>tc", function()
        -- Run cargo test with coverage
        vim.cmd("terminal cargo tarpaulin --out Html")
      end, vim.tbl_extend("force", opts, { desc = "Test: Coverage Report" }))
      
      vim.keymap.set("n", "<leader>tm", function()
        -- Run cargo test for current module
        local current_file = vim.fn.expand("%:t:r")
        vim.cmd("terminal cargo test " .. current_file)
      end, vim.tbl_extend("force", opts, { desc = "Test: Current Module" }))
      
      -- Benchmarking commands
      vim.keymap.set("n", "<leader>tB", function()
        vim.cmd("terminal cargo bench")
      end, vim.tbl_extend("force", opts, { desc = "Test: Run Benchmarks" }))
      
      vim.keymap.set("n", "<leader>tE", function()
        -- Run examples
        vim.cmd("terminal cargo run --example")
      end, vim.tbl_extend("force", opts, { desc = "Test: Run Examples" }))
    end,
  },

  -- Test coverage support
  {
    "andythigpen/nvim-coverage",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      require("coverage").setup({
        commands = true, -- Create commands
        highlights = {
          -- Customize highlight groups
          covered = { fg = "#b7f071" },   -- Green for covered lines
          uncovered = { fg = "#f06292" }, -- Red for uncovered lines
        },
        signs = {
          -- Customize signs
          covered = { hl = "CoverageCovered", text = "▎" },
          uncovered = { hl = "CoverageUncovered", text = "▎" },
        },
        summary = {
          -- Summary window configuration
          min_coverage = 80.0, -- Minimum coverage percentage to consider as good
        },
        lang = {
          -- Rust-specific configuration
          rust = {
            coverage_command = "cargo tarpaulin --out Xml",
            coverage_file = "cobertura.xml",
          },
        },
      })
      
      -- Coverage keymaps
      local opts = { silent = true }
      vim.keymap.set("n", "<leader>cct", function()
        require("coverage").toggle()
      end, vim.tbl_extend("force", opts, { desc = "Coverage: Toggle" }))
      
      vim.keymap.set("n", "<leader>ccs", function()
        require("coverage").summary()
      end, vim.tbl_extend("force", opts, { desc = "Coverage: Summary" }))
      
      vim.keymap.set("n", "<leader>ccl", function()
        require("coverage").load(true)
      end, vim.tbl_extend("force", opts, { desc = "Coverage: Load" }))
      
      vim.keymap.set("n", "<leader>ccr", function()
        vim.cmd("terminal cargo tarpaulin --out Html && open tarpaulin-report.html")
      end, vim.tbl_extend("force", opts, { desc = "Coverage: Generate Report" }))
    end,
  },

  -- Cargo test integration
  {
    "nvim-lua/plenary.nvim",
    config = function()
      -- Custom function to run cargo commands
      local function run_cargo_command(cmd, args)
        args = args or {}
        local full_cmd = "cargo " .. cmd .. " " .. table.concat(args, " ")
        
        vim.cmd("botright split")
        vim.cmd("terminal " .. full_cmd)
        vim.cmd("resize 15")
      end
      
      -- Cargo testing commands
      vim.api.nvim_create_user_command("CargoTest", function(opts)
        run_cargo_command("test", opts.fargs)
      end, { nargs = "*", desc = "Run cargo test with optional arguments" })
      
      vim.api.nvim_create_user_command("CargoTestRelease", function(opts)
        run_cargo_command("test", vim.list_extend({ "--release" }, opts.fargs))
      end, { nargs = "*", desc = "Run cargo test in release mode" })
      
      vim.api.nvim_create_user_command("CargoNextest", function(opts)
        run_cargo_command("nextest", vim.list_extend({ "run" }, opts.fargs))
      end, { nargs = "*", desc = "Run cargo nextest" })
      
      vim.api.nvim_create_user_command("CargoBench", function(opts)
        run_cargo_command("bench", opts.fargs)
      end, { nargs = "*", desc = "Run cargo bench" })
      
      vim.api.nvim_create_user_command("CargoDoc", function(opts)
        run_cargo_command("doc", vim.list_extend({ "--open" }, opts.fargs))
      end, { nargs = "*", desc = "Generate and open documentation" })
      
      vim.api.nvim_create_user_command("CargoClean", function()
        run_cargo_command("clean")
      end, { desc = "Clean cargo build artifacts" })
      
      vim.api.nvim_create_user_command("CargoUpdate", function()
        run_cargo_command("update")
      end, { desc = "Update cargo dependencies" })
      
      vim.api.nvim_create_user_command("CargoAudit", function()
        run_cargo_command("audit")
      end, { desc = "Run security audit on dependencies" })
      
      -- Keymaps for cargo commands
      local opts = { silent = true }
      vim.keymap.set("n", "<leader>ct", "<cmd>CargoTest<cr>", vim.tbl_extend("force", opts, { desc = "Cargo: Test" }))
      vim.keymap.set("n", "<leader>cT", "<cmd>CargoTestRelease<cr>", vim.tbl_extend("force", opts, { desc = "Cargo: Test Release" }))
      vim.keymap.set("n", "<leader>cn", "<cmd>CargoNextest<cr>", vim.tbl_extend("force", opts, { desc = "Cargo: Nextest" }))
      vim.keymap.set("n", "<leader>cb", "<cmd>CargoBench<cr>", vim.tbl_extend("force", opts, { desc = "Cargo: Bench" }))
      vim.keymap.set("n", "<leader>cd", "<cmd>CargoDoc<cr>", vim.tbl_extend("force", opts, { desc = "Cargo: Doc" }))
      vim.keymap.set("n", "<leader>cC", "<cmd>CargoClean<cr>", vim.tbl_extend("force", opts, { desc = "Cargo: Clean" }))
      vim.keymap.set("n", "<leader>cU", "<cmd>CargoUpdate<cr>", vim.tbl_extend("force", opts, { desc = "Cargo: Update" }))
      vim.keymap.set("n", "<leader>cA", "<cmd>CargoAudit<cr>", vim.tbl_extend("force", opts, { desc = "Cargo: Audit" }))
    end,
  },
}