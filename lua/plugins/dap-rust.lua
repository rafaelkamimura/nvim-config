return {
  -- Enhanced DAP configuration for Rust debugging
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
    config = function()
      local dap = require("dap")
      
      -- Configure codelldb adapter for Rust debugging
      dap.adapters.codelldb = {
        type = "server",
        port = "${port}",
        executable = {
          command = vim.fn.exepath("codelldb") or "/opt/homebrew/bin/codelldb",
          args = { "--port", "${port}" },
        },
      }
      
      -- Fallback to lldb if codelldb not available
      dap.adapters.lldb = {
        type = "executable",
        command = "/opt/homebrew/bin/lldb-vscode", -- Adjust path as needed
        name = "lldb",
      }
      
      -- Rust debugging configurations
      dap.configurations.rust = {
        {
          name = "Launch Rust Program",
          type = "codelldb",
          request = "launch",
          program = function()
            -- Look for target/debug directory and executables
            local cwd = vim.fn.getcwd()
            local target_dir = cwd .. "/target/debug"
            
            -- Try to find the most recently built executable
            local handle = io.popen(string.format("find %s -maxdepth 1 -type f -executable 2>/dev/null | head -1", target_dir))
            if handle then
              local result = handle:read("*a")
              handle:close()
              if result and result ~= "" then
                local executable = vim.trim(result)
                if executable ~= "" then
                  return executable
                end
              end
            end
            
            -- Fallback to user input
            return vim.fn.input("Path to executable: ", cwd .. "/target/debug/", "file")
          end,
          cwd = "${workspaceFolder}",
          stopOnEntry = false,
          args = {},
          runInTerminal = false,
          console = "integratedTerminal",
        },
        {
          name = "Launch Rust Program (with args)",
          type = "codelldb",
          request = "launch",
          program = function()
            return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/target/debug/", "file")
          end,
          cwd = "${workspaceFolder}",
          stopOnEntry = false,
          args = function()
            local args_string = vim.fn.input("Arguments: ")
            return vim.split(args_string, " ")
          end,
          runInTerminal = false,
          console = "integratedTerminal",
        },
        {
          name = "Attach to Rust Process",
          type = "codelldb",
          request = "attach",
          pid = function()
            local output = vim.fn.system("ps aux | grep -v grep | grep rust")
            if output == "" then
              print("No Rust processes found")
              return nil
            end
            
            local pid = tonumber(vim.fn.input("PID: "))
            return pid
          end,
          cwd = "${workspaceFolder}",
          stopOnEntry = false,
        },
        {
          name = "Launch Current Test",
          type = "codelldb",
          request = "launch",
          program = function()
            -- Build and run the current test
            local cwd = vim.fn.getcwd()
            local current_file = vim.fn.expand("%:p")
            
            -- Check if we're in a test file
            if not string.match(current_file, "test") and not string.match(vim.fn.getline("."), "#%[test%]") then
              print("Not in a test context")
              return nil
            end
            
            -- Build with debug symbols
            local cmd = "cd " .. cwd .. " && cargo test --no-run --message-format=json 2>/dev/null | jq -r 'select(.profile.test == true) | .executable' | head -1"
            local handle = io.popen(cmd)
            if handle then
              local result = handle:read("*a")
              handle:close()
              if result and result ~= "" then
                return vim.trim(result)
              end
            end
            
            return vim.fn.input("Path to test executable: ", cwd .. "/target/debug/deps/", "file")
          end,
          cwd = "${workspaceFolder}",
          stopOnEntry = false,
          args = function()
            -- Get test name from current cursor position or user input
            local line = vim.fn.getline(".")
            local test_name = string.match(line, "fn%s+([%w_]+)%s*%(")
            if not test_name then
              test_name = vim.fn.input("Test name: ")
            end
            return { test_name, "--exact" }
          end,
          runInTerminal = false,
          console = "integratedTerminal",
        },
      }
      
      -- Set up DAP signs and highlights
      vim.fn.sign_define("DapBreakpoint", { text = "🟥", texthl = "", linehl = "", numhl = "" })
      vim.fn.sign_define("DapBreakpointCondition", { text = "🟧", texthl = "", linehl = "", numhl = "" })
      vim.fn.sign_define("DapLogPoint", { text = "🟨", texthl = "", linehl = "", numhl = "" })
      vim.fn.sign_define("DapStopped", { text = "▶️", texthl = "", linehl = "DapStoppedLine", numhl = "" })
      vim.fn.sign_define("DapBreakpointRejected", { text = "🚫", texthl = "", linehl = "", numhl = "" })
      
      -- Set up DAP keymaps
      local opts = { silent = true }
      
      -- Basic debugging commands
      vim.keymap.set("n", "<F5>", function()
        require("dap").continue()
      end, vim.tbl_extend("force", opts, { desc = "Debug: Start/Continue" }))
      
      vim.keymap.set("n", "<F10>", function()
        require("dap").step_over()
      end, vim.tbl_extend("force", opts, { desc = "Debug: Step Over" }))
      
      vim.keymap.set("n", "<F11>", function()
        require("dap").step_into()
      end, vim.tbl_extend("force", opts, { desc = "Debug: Step Into" }))
      
      vim.keymap.set("n", "<F12>", function()
        require("dap").step_out()
      end, vim.tbl_extend("force", opts, { desc = "Debug: Step Out" }))
      
      vim.keymap.set("n", "<leader>db", function()
        require("dap").toggle_breakpoint()
      end, vim.tbl_extend("force", opts, { desc = "Debug: Toggle Breakpoint" }))
      
      vim.keymap.set("n", "<leader>dB", function()
        require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: "))
      end, vim.tbl_extend("force", opts, { desc = "Debug: Set Conditional Breakpoint" }))
      
      vim.keymap.set("n", "<leader>dp", function()
        require("dap").set_breakpoint(nil, nil, vim.fn.input("Log point message: "))
      end, vim.tbl_extend("force", opts, { desc = "Debug: Set Log Point" }))
      
      vim.keymap.set("n", "<leader>dr", function()
        require("dap").repl.open()
      end, vim.tbl_extend("force", opts, { desc = "Debug: Open REPL" }))
      
      vim.keymap.set("n", "<leader>dl", function()
        require("dap").run_last()
      end, vim.tbl_extend("force", opts, { desc = "Debug: Run Last" }))
      
      vim.keymap.set("n", "<leader>dt", function()
        require("dap").terminate()
      end, vim.tbl_extend("force", opts, { desc = "Debug: Terminate" }))
      
      -- Rust-specific debugging commands
      vim.keymap.set("n", "<leader>dR", function()
        vim.cmd.RustLsp("debuggables")
      end, vim.tbl_extend("force", opts, { desc = "Debug: Rust Debuggables" }))
    end,
  },

  -- DAP UI for better debugging experience
  {
    "rcarriga/nvim-dap-ui",
    dependencies = { "mfussenegger/nvim-dap", "nvim-neotest/nvim-nio" },
    keys = {
      { "<leader>du", function() require("dapui").toggle({ }) end, desc = "Debug: Toggle UI" },
      { "<leader>de", function() require("dapui").eval() end, desc = "Debug: Evaluate", mode = {"n", "v"} },
    },
    opts = {},
    config = function(_, opts)
      local dap = require("dap")
      local dapui = require("dapui")
      
      dapui.setup(opts)
      
      -- Automatically open/close DAP UI
      dap.listeners.after.event_initialized["dapui_config"] = function()
        dapui.open({})
      end
      dap.listeners.before.event_terminated["dapui_config"] = function()
        dapui.close({})
      end
      dap.listeners.before.event_exited["dapui_config"] = function()
        dapui.close({})
      end
    end,
  },

  -- Virtual text for DAP
  {
    "theHamsta/nvim-dap-virtual-text",
    dependencies = { "mfussenegger/nvim-dap" },
    opts = {
      enabled = true,
      enabled_commands = true,
      highlight_changed_variables = true,
      highlight_new_as_changed = false,
      show_stop_reason = true,
      commented = false,
      only_first_definition = true,
      all_references = false,
      filter_references_pattern = "<module",
      virt_text_pos = "eol",
      all_frames = false,
      virt_lines = false,
      virt_text_win_col = nil,
    },
  },
}