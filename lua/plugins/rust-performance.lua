return {
  -- Performance optimizations for Rust development
  {
    "nvim-lua/plenary.nvim",
    config = function()
      -- Set Rust-specific LSP performance optimizations
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "rust",
        callback = function()
          -- Increase updatetime for faster completion and hover
          vim.opt.updatetime = 250
          
          -- Optimize for large Rust files
          if vim.fn.line("$") > 10000 then
            -- Disable some expensive features for very large files
            vim.opt_local.cursorline = false
            vim.opt_local.foldmethod = "manual"
            vim.opt_local.syntax = "off"
            vim.cmd("NoMatchParen")
          end
          
          -- Set Rust-specific completion settings
          vim.opt_local.completeopt = { "menu", "menuone", "noselect" }
          
          -- Optimize undo settings for Rust files
          vim.opt_local.undolevels = 1000
          vim.opt_local.undoreload = 10000
        end,
        desc = "Optimize Neovim for Rust files"
      })
      
      -- Memory optimization function
      local function optimize_rust_analyzer_memory()
        -- Set environment variables for rust-analyzer performance
        vim.env.RA_LOG = "rust_analyzer=warn" -- Reduce log verbosity
        vim.env.RUST_BACKTRACE = "0" -- Disable backtraces for performance
        
        -- Set rust-analyzer specific memory limits
        if vim.fn.has("unix") == 1 then
          -- On Unix systems, we can set memory limits
          local total_memory = tonumber(vim.fn.system("sysctl -n hw.memsize 2>/dev/null || echo 8589934592")) or 8589934592
          local memory_gb = math.floor(total_memory / 1024 / 1024 / 1024)
          
          -- Allocate 25% of system memory to rust-analyzer, max 4GB
          local ra_memory_gb = math.min(4, math.floor(memory_gb * 0.25))
          vim.env.RA_HEAP_SIZE = tostring(ra_memory_gb * 1024) .. "M"
        end
      end
      
      -- Apply optimizations on Rust project detection
      vim.api.nvim_create_autocmd("BufEnter", {
        pattern = "*.rs",
        once = true, -- Only run once per session
        callback = optimize_rust_analyzer_memory,
        desc = "Optimize rust-analyzer memory usage"
      })
      
      -- Function to clean up Rust build artifacts for better performance
      local function clean_rust_artifacts()
        local cwd = vim.fn.getcwd()
        local target_dir = cwd .. "/target"
        
        if vim.fn.isdirectory(target_dir) == 1 then
          local choice = vim.fn.confirm(
            "Clean Rust build artifacts in " .. target_dir .. "?",
            "&Yes\n&No", 
            2
          )
          
          if choice == 1 then
            vim.cmd("terminal cargo clean")
            print("Cleaning Rust build artifacts...")
          end
        end
      end
      
      -- Create user command for cleaning artifacts
      vim.api.nvim_create_user_command("RustCleanArtifacts", clean_rust_artifacts, {
        desc = "Clean Rust build artifacts to free up space"
      })
      
      -- Function to optimize Cargo.toml for faster builds
      local function suggest_cargo_optimizations()
        local cargo_toml = vim.fn.findfile("Cargo.toml", ".;")
        if cargo_toml == "" then
          print("No Cargo.toml found")
          return
        end
        
        local suggestions = {
          "# Add these to your Cargo.toml for faster builds:",
          "",
          "[profile.dev]",
          "# Faster compilation at the cost of runtime performance",
          "opt-level = 1",
          "debug = true",
          "debug-assertions = true",
          "overflow-checks = true",
          "lto = false",
          "panic = 'unwind'",
          "incremental = true",
          "codegen-units = 256",
          "rpath = false",
          "",
          "[profile.release]",
          "# Optimize for performance",
          "opt-level = 3",
          "debug = false",
          "debug-assertions = false",
          "overflow-checks = false",
          "lto = 'thin'",
          "panic = 'abort'",
          "incremental = false",
          "codegen-units = 1",
          "rpath = false",
          "",
          "# For even faster builds during development",
          "[profile.dev.package.\"*\"]",
          "opt-level = 3",
          "",
          "# Workspace optimization",
          "[workspace]",
          "resolver = \"2\"",
          "",
          "# Build cache optimization",
          "[build]",
          "incremental = true",
          "pipelining = true",
        }
        
        -- Create a new buffer with suggestions
        vim.cmd("vnew")
        vim.api.nvim_buf_set_lines(0, 0, -1, false, suggestions)
        vim.bo.filetype = "toml"
        vim.bo.buftype = "nofile"
        vim.api.nvim_buf_set_name(0, "Cargo Optimization Suggestions")
      end
      
      -- Create user command for cargo optimizations
      vim.api.nvim_create_user_command("RustOptimizeCargo", suggest_cargo_optimizations, {
        desc = "Show Cargo.toml optimization suggestions"
      })
      
      -- Keymaps for performance tools
      local opts = { silent = true }
      vim.keymap.set("n", "<leader>rO", suggest_cargo_optimizations, 
        vim.tbl_extend("force", opts, { desc = "Rust: Optimize Cargo.toml" }))
      vim.keymap.set("n", "<leader>rZ", clean_rust_artifacts, 
        vim.tbl_extend("force", opts, { desc = "Rust: Clean Artifacts" }))
    end,
  },

  -- Improved syntax highlighting for better performance
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      -- Optimize treesitter for Rust
      local ts_config = require("nvim-treesitter.configs")
      
      opts.highlight = opts.highlight or {}
      opts.highlight.additional_vim_regex_highlighting = { "rust" }
      opts.highlight.disable = function(lang, buf)
        -- Disable treesitter highlighting for very large Rust files
        local max_filesize = 100 * 1024 -- 100 KB
        local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
        if ok and stats and stats.size > max_filesize then
          return true
        end
      end
      
      -- Enable incremental selection for Rust
      opts.incremental_selection = opts.incremental_selection or {}
      opts.incremental_selection.enable = true
      opts.incremental_selection.keymaps = {
        init_selection = "<C-space>",
        node_incremental = "<C-space>",
        scope_incremental = "<C-s>",
        node_decremental = "<M-space>",
      }
      
      -- Enable text objects for Rust
      opts.textobjects = opts.textobjects or {}
      opts.textobjects.select = opts.textobjects.select or {}
      opts.textobjects.select.enable = true
      opts.textobjects.select.keymaps = {
        ["af"] = "@function.outer",
        ["if"] = "@function.inner",
        ["ac"] = "@class.outer",
        ["ic"] = "@class.inner",
        ["aa"] = "@parameter.outer",
        ["ia"] = "@parameter.inner",
      }
      
      return opts
    end,
  },

  -- Enhanced completion performance for Rust
  {
    "hrsh7th/nvim-cmp",
    optional = true,
    opts = function(_, opts)
      -- Optimize completion for Rust files
      opts.performance = opts.performance or {}
      opts.performance.debounce = 60
      opts.performance.throttle = 30
      opts.performance.fetching_timeout = 500
      opts.performance.confirm_resolve_timeout = 80
      opts.performance.async_budget = 1
      opts.performance.max_view_entries = 200
      
      -- Rust-specific completion configuration
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "rust",
        callback = function()
          local cmp = require("cmp")
          cmp.setup.buffer({
            sources = cmp.config.sources({
              { name = "nvim_lsp", priority = 1000 },
              { name = "luasnip", priority = 750 },
              { name = "buffer", priority = 500, keyword_length = 3 },
              { name = "path", priority = 250 },
            }),
            completion = {
              autocomplete = {
                require("cmp.types").cmp.TriggerEvent.TextChanged,
              },
              completeopt = "menu,menuone,noinsert",
              keyword_length = 2,
            },
            experimental = {
              ghost_text = true,
            },
          })
        end,
        desc = "Optimize completion for Rust files"
      })
      
      return opts
    end,
  },

  -- File watching optimization for large Rust projects
  {
    "nvim-lua/plenary.nvim",
    config = function()
      -- Optimize file watching for Rust projects
      local function optimize_file_watching()
        -- Ignore common Rust build directories
        vim.opt.wildignore:append({
          "*/target/*",
          "*/target/debug/*",
          "*/target/release/*",
          "*/target/doc/*",
          "*/Cargo.lock",
          "*/.cargo/*",
        })
        
        -- Set appropriate backup and swap file locations
        local cache_dir = vim.fn.stdpath("cache")
        vim.opt.backupdir = cache_dir .. "/backup"
        vim.opt.directory = cache_dir .. "/swap"
        vim.opt.undodir = cache_dir .. "/undo"
        
        -- Create directories if they don't exist
        for _, dir in ipairs({ "backup", "swap", "undo" }) do
          local path = cache_dir .. "/" .. dir
          if vim.fn.isdirectory(path) == 0 then
            vim.fn.mkdir(path, "p")
          end
        end
      end
      
      -- Apply file watching optimizations
      vim.api.nvim_create_autocmd("VimEnter", {
        once = true,
        callback = optimize_file_watching,
        desc = "Optimize file watching for Rust projects"
      })
      
      -- Function to show project statistics
      local function show_project_stats()
        local stats = {}
        
        -- Count Rust files
        local rust_files = vim.fn.system("find . -name '*.rs' | wc -l")
        stats["Rust files"] = vim.trim(rust_files)
        
        -- Count lines of Rust code
        local rust_lines = vim.fn.system("find . -name '*.rs' -exec wc -l {} + | tail -1 | awk '{print $1}'")
        stats["Lines of Rust"] = vim.trim(rust_lines)
        
        -- Check target directory size
        local target_size = vim.fn.system("du -sh target 2>/dev/null | cut -f1")
        if target_size ~= "" then
          stats["Target directory size"] = vim.trim(target_size)
        end
        
        -- Check if using workspaces
        local workspace_members = vim.fn.system("grep -c 'members.*=' Cargo.toml 2>/dev/null")
        if tonumber(workspace_members) and tonumber(workspace_members) > 0 then
          stats["Workspace"] = "Yes"
        end
        
        -- Display stats
        local lines = { "Rust Project Statistics:", "" }
        for key, value in pairs(stats) do
          table.insert(lines, string.format("%-20s: %s", key, value))
        end
        
        -- Create floating window with stats
        local buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
        
        local width = math.max(40, vim.api.nvim_strwidth(lines[1]) + 4)
        local height = #lines + 2
        
        local win = vim.api.nvim_open_win(buf, false, {
          relative = "editor",
          width = width,
          height = height,
          row = math.floor((vim.o.lines - height) / 2),
          col = math.floor((vim.o.columns - width) / 2),
          style = "minimal",
          border = "rounded",
          title = " Project Stats ",
          title_pos = "center",
        })
        
        -- Auto-close after 5 seconds
        vim.defer_fn(function()
          if vim.api.nvim_win_is_valid(win) then
            vim.api.nvim_win_close(win, true)
          end
        end, 5000)
      end
      
      -- Create user command for project stats
      vim.api.nvim_create_user_command("RustProjectStats", show_project_stats, {
        desc = "Show Rust project statistics"
      })
      
      -- Keymap for project stats
      vim.keymap.set("n", "<leader>rS", show_project_stats, {
        silent = true,
        desc = "Rust: Project Statistics"
      })
    end,
  },

  -- Memory monitoring for development
  {
    "nvim-lua/plenary.nvim",
    config = function()
      -- Function to monitor Neovim memory usage
      local function show_memory_usage()
        local memory_kb = vim.fn.system("ps -o rss= -p " .. vim.fn.getpid())
        local memory_mb = math.floor(tonumber(memory_kb) / 1024)
        
        print(string.format("Neovim memory usage: %d MB", memory_mb))
        
        -- Warn if memory usage is high
        if memory_mb > 1024 then
          print("⚠️  High memory usage detected. Consider restarting or cleaning up.")
        end
      end
      
      -- Create user command for memory monitoring
      vim.api.nvim_create_user_command("RustMemoryUsage", show_memory_usage, {
        desc = "Show Neovim memory usage"
      })
      
      -- Auto-check memory usage in large Rust projects
      vim.api.nvim_create_autocmd("BufEnter", {
        pattern = "*.rs",
        callback = function()
          -- Only check if we haven't checked recently
          if not vim.g.last_memory_check or os.time() - vim.g.last_memory_check > 300 then
            vim.g.last_memory_check = os.time()
            
            -- Check if this is a large project
            local rust_files = tonumber(vim.fn.system("find . -name '*.rs' | wc -l"))
            if rust_files and rust_files > 100 then
              vim.defer_fn(show_memory_usage, 1000)
            end
          end
        end,
        desc = "Monitor memory usage in large Rust projects"
      })
    end,
  },
}