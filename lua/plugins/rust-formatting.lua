return {
  -- Enhanced formatting configuration for Rust
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
          args = {
            "--edition", "2021",
            "--emit", "stdout",
            "--quiet",
          },
          stdin = true,
          cwd = require("conform.util").root_file({ "Cargo.toml" }),
        },
        taplo = {
          command = "taplo",
          args = { "format", "-" },
          stdin = true,
        },
      },
      -- Format on save for Rust files
      format_on_save = function(bufnr)
        -- Disable format_on_save for certain filetypes
        if vim.bo[bufnr].filetype == "rust" then
          return {
            timeout_ms = 500,
            lsp_fallback = true,
          }
        end
      end,
    },
  },

  -- Enhanced linting configuration for Rust
  {
    "mfussenegger/nvim-lint",
    optional = true,
    opts = {
      linters_by_ft = {
        rust = { "clippy" },
      },
      linters = {
        clippy = {
          cmd = "cargo",
          args = {
            "clippy",
            "--message-format=json",
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
            "--allow", "clippy::single_char_lifetime_names",
            "--allow", "clippy::exhaustive_structs",
            "--allow", "clippy::exhaustive_enums",
          },
          stdin = false,
          stream = "stderr",
          ignore_exitcode = true,
          parser = function(output, bufnr)
            local diagnostics = {}
            
            for line in output:gmatch("[^\r\n]+") do
              local ok, decoded = pcall(vim.json.decode, line)
              if ok and decoded.message then
                local msg = decoded.message
                if msg.spans and #msg.spans > 0 then
                  local span = msg.spans[1]
                  if span.file_name == vim.api.nvim_buf_get_name(bufnr) then
                    table.insert(diagnostics, {
                      lnum = span.line_start - 1,
                      col = span.column_start - 1,
                      end_lnum = span.line_end - 1,
                      end_col = span.column_end - 1,
                      severity = msg.level == "error" and vim.diagnostic.severity.ERROR
                        or msg.level == "warning" and vim.diagnostic.severity.WARN
                        or vim.diagnostic.severity.INFO,
                      message = msg.message,
                      source = "clippy",
                      code = msg.code and msg.code.code or nil,
                    })
                  end
                end
              end
            end
            
            return diagnostics
          end,
        },
      },
    },
  },

  -- Rustfmt configuration file setup
  {
    "nvim-lua/plenary.nvim",
    config = function()
      -- Function to create rustfmt.toml if it doesn't exist
      local function setup_rustfmt_config()
        local cwd = vim.fn.getcwd()
        local rustfmt_path = cwd .. "/rustfmt.toml"
        
        -- Check if rustfmt.toml already exists
        if vim.fn.filereadable(rustfmt_path) == 0 then
          local rustfmt_config = [[# Rustfmt configuration
# See https://rust-lang.github.io/rustfmt/ for all options

# Basic formatting
edition = "2021"
hard_tabs = false
tab_spaces = 4
max_width = 100
use_small_heuristics = "Default"

# Import organization
imports_granularity = "Crate"
reorder_imports = true
group_imports = "StdExternalCrate"

# Code style
wrap_comments = true
comment_width = 80
normalize_comments = true
normalize_doc_attributes = true

# Function and control flow formatting
fn_params_layout = "Tall"
brace_style = "SameLineWhere"
control_brace_style = "AlwaysSameLine"
trailing_comma = "Vertical"
match_arm_blocks = true
force_multiline_blocks = true

# Expression formatting
overflow_delimited_expr = true
indent_style = "Block"
where_single_line = true

# Advanced options
unstable_features = false
version = "Two"

# Specific formatting rules
newline_style = "Unix"
remove_nested_parens = true
use_field_init_shorthand = true
force_explicit_abi = true
condense_wildcard_suffixes = true

# Line breaking
single_line_if_else_max_width = 50
chain_width = 60
fn_call_width = 60
attr_fn_like_width = 70
struct_lit_width = 18
struct_variant_width = 35
array_width = 60
]]
          
          -- Write the configuration
          local file = io.open(rustfmt_path, "w")
          if file then
            file:write(rustfmt_config)
            file:close()
            print("Created rustfmt.toml with recommended settings")
          else
            print("Failed to create rustfmt.toml")
          end
        end
      end
      
      -- Function to create .clippy.toml if it doesn't exist
      local function setup_clippy_config()
        local cwd = vim.fn.getcwd()
        local clippy_path = cwd .. "/clippy.toml"
        
        -- Check if clippy.toml already exists
        if vim.fn.filereadable(clippy_path) == 0 then
          local clippy_config = [[# Clippy configuration
# See https://doc.rust-lang.org/clippy/configuration.html for all options

# Lint levels
avoid-breaking-exported-api = false
msrv = "1.70.0"

# Complexity thresholds
type-complexity-threshold = 250
too-many-arguments-threshold = 7
trivial-copy-size-limit = 64
pass-by-value-size-limit = 256
vec-box-size-threshold = 4096
max-trait-bounds = 3
max-struct-bools = 3
max-fn-params-bools = 3

# Naming conventions
enum-variant-name-threshold = 3

# Documentation
missing-docs-in-private-items = false

# Performance
single-char-binding-names-threshold = 4

# Style preferences
semicolon-if-nothing-returned = true
semicolon-outside-block = true
]]
          
          -- Write the configuration
          local file = io.open(clippy_path, "w")
          if file then
            file:write(clippy_config)
            file:close()
            print("Created clippy.toml with recommended settings")
          else
            print("Failed to create clippy.toml")
          end
        end
      end
      
      -- Create user commands for setting up configuration files
      vim.api.nvim_create_user_command("RustSetupFmt", setup_rustfmt_config, {
        desc = "Create rustfmt.toml with recommended settings"
      })
      
      vim.api.nvim_create_user_command("RustSetupClippy", setup_clippy_config, {
        desc = "Create clippy.toml with recommended settings"
      })
      
      vim.api.nvim_create_user_command("RustSetupAll", function()
        setup_rustfmt_config()
        setup_clippy_config()
      end, {
        desc = "Create both rustfmt.toml and clippy.toml with recommended settings"
      })
      
      -- Auto-setup on Rust project detection
      vim.api.nvim_create_autocmd("BufEnter", {
        pattern = "*.rs",
        callback = function()
          local cargo_toml = vim.fn.findfile("Cargo.toml", ".;")
          if cargo_toml ~= "" then
            -- We're in a Rust project, optionally set up configs
            -- (commented out to avoid auto-creation, user can run commands manually)
            -- setup_rustfmt_config()
            -- setup_clippy_config()
          end
        end,
        desc = "Detect Rust project and optionally setup configuration files"
      })
    end,
  },

  -- Additional formatting tools
  {
    "williamboman/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, {
        "taplo", -- TOML formatter
      })
    end,
  },

  -- Enhanced Rust file type configuration
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      -- Additional file type associations
      vim.filetype.add({
        extension = {
          rs = "rust",
          toml = "toml",
        },
        filename = {
          ["Cargo.toml"] = "toml",
          ["Cargo.lock"] = "toml",
          ["rust-toolchain"] = "toml",
          ["rust-toolchain.toml"] = "toml",
        },
      })
      
      return opts
    end,
  },

  -- Auto-formatting keymaps
  {
    "nvim-lua/plenary.nvim",
    config = function()
      -- Enhanced formatting keymaps
      local opts = { silent = true }
      
      vim.keymap.set("n", "<leader>rf", function()
        vim.cmd("Format")
      end, vim.tbl_extend("force", opts, { desc = "Format: Current Buffer" }))
      
      vim.keymap.set("v", "<leader>rf", function()
        vim.cmd("'<,'>Format")
      end, vim.tbl_extend("force", opts, { desc = "Format: Selection" }))
      
      vim.keymap.set("n", "<leader>rF", function()
        vim.cmd("FormatWrite")
      end, vim.tbl_extend("force", opts, { desc = "Format: Save and Format" }))
      
      -- Clippy keymaps
      vim.keymap.set("n", "<leader>rC", function()
        vim.cmd("Lint")
      end, vim.tbl_extend("force", opts, { desc = "Clippy: Lint Current Buffer" }))
      
      vim.keymap.set("n", "<leader>rL", function()
        vim.cmd("terminal cargo clippy --workspace --all-targets --all-features")
      end, vim.tbl_extend("force", opts, { desc = "Clippy: Lint Workspace" }))
      
      -- Fix all clippy suggestions
      vim.keymap.set("n", "<leader>rX", function()
        vim.cmd("terminal cargo clippy --workspace --all-targets --all-features --fix")
      end, vim.tbl_extend("force", opts, { desc = "Clippy: Fix All Issues" }))
      
      -- Format all Rust files in project
      vim.keymap.set("n", "<leader>rA", function()
        vim.cmd("terminal cargo fmt")
      end, vim.tbl_extend("force", opts, { desc = "Format: All Rust Files" }))
      
      -- Check formatting without changing files
      vim.keymap.set("n", "<leader>rK", function()
        vim.cmd("terminal cargo fmt -- --check")
      end, vim.tbl_extend("force", opts, { desc = "Format: Check Only" }))
    end,
  },
}