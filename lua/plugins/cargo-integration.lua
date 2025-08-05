return {
  -- Comprehensive Cargo integration and workspace management
  {
    "nvim-lua/plenary.nvim",
    config = function()
      local Path = require("plenary.path")
      local Job = require("plenary.job")
      
      -- Cargo workspace detection and management
      local function find_cargo_root()
        local current_file = vim.fn.expand("%:p")
        local current_dir = vim.fn.fnamemodify(current_file, ":h")
        
        -- Look for Cargo.toml in current directory and parent directories
        local cargo_toml = vim.fn.findfile("Cargo.toml", current_dir .. ";")
        if cargo_toml ~= "" then
          return vim.fn.fnamemodify(cargo_toml, ":h")
        end
        
        return nil
      end
      
      -- Function to get workspace members
      local function get_workspace_members()
        local cargo_root = find_cargo_root()
        if not cargo_root then
          return {}
        end
        
        local cargo_toml = cargo_root .. "/Cargo.toml"
        local members = {}
        
        -- Read Cargo.toml and extract workspace members
        if vim.fn.filereadable(cargo_toml) == 1 then
          local content = table.concat(vim.fn.readfile(cargo_toml), "\n")
          
          -- Simple parsing for workspace members
          local in_workspace = false
          for line in content:gmatch("[^\r\n]+") do
            if line:match("^%[workspace%]") then
              in_workspace = true
            elseif line:match("^%[") then
              in_workspace = false
            elseif in_workspace and line:match("members%s*=") then
              -- Extract members from the array
              local members_str = line:gsub(".*members%s*=%s*", "")
              members_str = members_str:gsub("%].*", ""):gsub("%[", "")
              
              for member in members_str:gmatch('"([^"]*)"') do
                table.insert(members, member)
              end
            end
          end
        end
        
        return members
      end
      
      -- Function to run cargo commands with proper working directory
      local function run_cargo_command(cmd, args, opts)
        opts = opts or {}
        local cargo_root = find_cargo_root()
        
        if not cargo_root then
          vim.notify("Not in a Cargo project", vim.log.levels.ERROR)
          return
        end
        
        args = args or {}
        local full_args = vim.list_extend({ cmd }, args)
        
        -- Create terminal or run in background
        if opts.terminal ~= false then
          vim.cmd("cd " .. cargo_root)
          vim.cmd(string.format("botright split | terminal cargo %s", table.concat(full_args, " ")))
          vim.cmd("resize 15")
          vim.cmd("cd -") -- Return to original directory
        else
          Job:new({
            command = "cargo",
            args = full_args,
            cwd = cargo_root,
            on_exit = function(j, return_val)
              if opts.on_complete then
                opts.on_complete(j:result(), return_val)
              end
            end,
          }):start()
        end
      end
      
      -- Enhanced cargo commands
      local cargo_commands = {
        -- Build commands
        build = { "build" },
        build_release = { "build", "--release" },
        build_all = { "build", "--workspace" },
        
        -- Test commands
        test = { "test" },
        test_release = { "test", "--release" },
        test_workspace = { "test", "--workspace" },
        test_doc = { "test", "--doc" },
        
        -- Check commands
        check = { "check" },
        check_all = { "check", "--workspace", "--all-targets" },
        clippy = { "clippy", "--workspace", "--all-targets" },
        clippy_fix = { "clippy", "--workspace", "--all-targets", "--fix" },
        
        -- Format commands
        fmt = { "fmt" },
        fmt_check = { "fmt", "--", "--check" },
        
        -- Documentation
        doc = { "doc", "--open" },
        doc_deps = { "doc", "--open", "--document-private-items" },
        
        -- Utility commands
        clean = { "clean" },
        update = { "update" },
        tree = { "tree" },
        audit = { "audit" },
        
        -- Advanced commands
        expand = { "expand" },
        bloat = { "bloat" },
        deps = { "tree", "--duplicates" },
        outdated = { "outdated" },
        
        -- Benchmarking
        bench = { "bench" },
        criterion = { "criterion" },
        
        -- Release management
        publish = { "publish", "--dry-run" },
        package = { "package" },
        
        -- Workspace commands
        workspace_graph = { "tree", "--workspace-dependencies" },
        workspace_check = { "check", "--workspace" },
      }
      
      -- Create user commands for all cargo operations
      for name, args in pairs(cargo_commands) do
        local cmd_name = "Cargo" .. name:gsub("^%l", string.upper):gsub("_(%l)", function(c) return string.upper(c) end)
        
        vim.api.nvim_create_user_command(cmd_name, function(opts)
          local user_args = opts.fargs or {}
          local final_args = vim.list_extend(vim.deepcopy(args), user_args)
          run_cargo_command(final_args[1], vim.list_slice(final_args, 2))
        end, {
          nargs = "*",
          desc = "Run cargo " .. table.concat(args, " ")
        })
      end
      
      -- Smart project switcher for workspaces
      local function switch_workspace_member()
        local members = get_workspace_members()
        if #members == 0 then
          vim.notify("No workspace members found", vim.log.levels.INFO)
          return
        end
        
        vim.ui.select(members, {
          prompt = "Switch to workspace member:",
          format_item = function(item)
            return item
          end,
        }, function(choice)
          if choice then
            local cargo_root = find_cargo_root()
            local member_path = cargo_root .. "/" .. choice
            
            if vim.fn.isdirectory(member_path) == 1 then
              vim.cmd("cd " .. member_path)
              vim.notify("Switched to " .. choice)
              
              -- Find main.rs or lib.rs and open it
              local main_file = member_path .. "/src/main.rs"
              local lib_file = member_path .. "/src/lib.rs"
              
              if vim.fn.filereadable(main_file) == 1 then
                vim.cmd("edit " .. main_file)
              elseif vim.fn.filereadable(lib_file) == 1 then
                vim.cmd("edit " .. lib_file)
              end
            else
              vim.notify("Member directory not found: " .. member_path, vim.log.levels.ERROR)
            end
          end
        end)
      end
      
      -- Function to create a new Rust project
      local function create_rust_project()
        vim.ui.input({
          prompt = "Project name: ",
        }, function(name)
          if name and name ~= "" then
            vim.ui.select({ "bin", "lib" }, {
              prompt = "Project type:",
            }, function(project_type)
              if project_type then
                local args = { "new", name }
                if project_type == "lib" then
                  table.insert(args, "--lib")
                end
                
                run_cargo_command("new", vim.list_slice(args, 2), {
                  on_complete = function(result, return_val)
                    if return_val == 0 then
                      vim.notify("Created project: " .. name)
                      -- Switch to the new project
                      vim.cmd("cd " .. name)
                      local main_file = project_type == "lib" and "src/lib.rs" or "src/main.rs"
                      vim.cmd("edit " .. main_file)
                    else
                      vim.notify("Failed to create project", vim.log.levels.ERROR)
                    end
                  end,
                  terminal = false,
                })
              end
            end)
          end
        end)
      end
      
      -- Function to add dependencies interactively
      local function add_dependency()
        vim.ui.input({
          prompt = "Dependency name (e.g., serde, tokio): ",
        }, function(dep_name)
          if dep_name and dep_name ~= "" then
            local features_input = vim.fn.input("Features (optional): ")
            local version_input = vim.fn.input("Version (optional): ")
            
            local args = { "add", dep_name }
            
            if features_input ~= "" then
              table.insert(args, "--features")
              table.insert(args, features_input)
            end
            
            if version_input ~= "" then
              table.insert(args, "--version")
              table.insert(args, version_input)
            end
            
            run_cargo_command("add", vim.list_slice(args, 2))
          end
        end)
      end
      
      -- Function to remove dependencies
      local function remove_dependency()
        -- Get current dependencies from Cargo.toml
        local cargo_root = find_cargo_root()
        if not cargo_root then
          vim.notify("Not in a Cargo project", vim.log.levels.ERROR)
          return
        end
        
        local cargo_toml = cargo_root .. "/Cargo.toml"
        if vim.fn.filereadable(cargo_toml) == 0 then
          vim.notify("Cargo.toml not found", vim.log.levels.ERROR)
          return
        end
        
        -- Simple parsing to get dependencies
        local content = table.concat(vim.fn.readfile(cargo_toml), "\n")
        local deps = {}
        local in_deps = false
        
        for line in content:gmatch("[^\r\n]+") do
          if line:match("^%[dependencies%]") then
            in_deps = true
          elseif line:match("^%[") then
            in_deps = false
          elseif in_deps and line:match("^([%w_-]+)%s*=") then
            local dep = line:match("^([%w_-]+)%s*=")
            if dep then
              table.insert(deps, dep)
            end
          end
        end
        
        if #deps == 0 then
          vim.notify("No dependencies found", vim.log.levels.INFO)
          return
        end
        
        vim.ui.select(deps, {
          prompt = "Remove dependency:",
        }, function(choice)
          if choice then
            run_cargo_command("remove", { choice })
          end
        end)
      end
      
      -- Create user commands for workspace management
      vim.api.nvim_create_user_command("CargoSwitchMember", switch_workspace_member, {
        desc = "Switch to a workspace member"
      })
      
      vim.api.nvim_create_user_command("CargoNewProject", create_rust_project, {
        desc = "Create a new Rust project"
      })
      
      vim.api.nvim_create_user_command("CargoAddDep", add_dependency, {
        desc = "Add a dependency to Cargo.toml"
      })
      
      vim.api.nvim_create_user_command("CargoRemoveDep", remove_dependency, {
        desc = "Remove a dependency from Cargo.toml"
      })
      
      -- Enhanced keymaps for cargo operations
      local opts = { silent = true }
      
      -- Build and check operations
      vim.keymap.set("n", "<leader>cb", "<cmd>CargoBuild<cr>", 
        vim.tbl_extend("force", opts, { desc = "Cargo: Build" }))
      vim.keymap.set("n", "<leader>cB", "<cmd>CargoBuildRelease<cr>", 
        vim.tbl_extend("force", opts, { desc = "Cargo: Build Release" }))
      vim.keymap.set("n", "<leader>cc", "<cmd>CargoCheck<cr>", 
        vim.tbl_extend("force", opts, { desc = "Cargo: Check" }))
      vim.keymap.set("n", "<leader>cC", "<cmd>CargoCheckAll<cr>", 
        vim.tbl_extend("force", opts, { desc = "Cargo: Check All" }))
      
      -- Test operations
      vim.keymap.set("n", "<leader>ct", "<cmd>CargoTest<cr>", 
        vim.tbl_extend("force", opts, { desc = "Cargo: Test" }))
      vim.keymap.set("n", "<leader>cT", "<cmd>CargoTestRelease<cr>", 
        vim.tbl_extend("force", opts, { desc = "Cargo: Test Release" }))
      vim.keymap.set("n", "<leader>cw", "<cmd>CargoTestWorkspace<cr>", 
        vim.tbl_extend("force", opts, { desc = "Cargo: Test Workspace" }))
      
      -- Clippy and formatting
      vim.keymap.set("n", "<leader>cl", "<cmd>CargoClippy<cr>", 
        vim.tbl_extend("force", opts, { desc = "Cargo: Clippy" }))
      vim.keymap.set("n", "<leader>cL", "<cmd>CargoClippyFix<cr>", 
        vim.tbl_extend("force", opts, { desc = "Cargo: Clippy Fix" }))
      vim.keymap.set("n", "<leader>cf", "<cmd>CargoFmt<cr>", 
        vim.tbl_extend("force", opts, { desc = "Cargo: Format" }))
      vim.keymap.set("n", "<leader>cF", "<cmd>CargoFmtCheck<cr>", 
        vim.tbl_extend("force", opts, { desc = "Cargo: Format Check" }))
      
      -- Documentation
      vim.keymap.set("n", "<leader>cd", "<cmd>CargoDoc<cr>", 
        vim.tbl_extend("force", opts, { desc = "Cargo: Documentation" }))
      vim.keymap.set("n", "<leader>cD", "<cmd>CargoDocDeps<cr>", 
        vim.tbl_extend("force", opts, { desc = "Cargo: Doc with Dependencies" }))
      
      -- Workspace operations
      vim.keymap.set("n", "<leader>cs", switch_workspace_member, 
        vim.tbl_extend("force", opts, { desc = "Cargo: Switch Member" }))
      vim.keymap.set("n", "<leader>cg", "<cmd>CargoTree<cr>", 
        vim.tbl_extend("force", opts, { desc = "Cargo: Dependency Tree" }))
      
      -- Project management
      vim.keymap.set("n", "<leader>cn", create_rust_project, 
        vim.tbl_extend("force", opts, { desc = "Cargo: New Project" }))
      vim.keymap.set("n", "<leader>ca", add_dependency, 
        vim.tbl_extend("force", opts, { desc = "Cargo: Add Dependency" }))
      vim.keymap.set("n", "<leader>cr", remove_dependency, 
        vim.tbl_extend("force", opts, { desc = "Cargo: Remove Dependency" }))
      
      -- Utility operations
      vim.keymap.set("n", "<leader>cu", "<cmd>CargoUpdate<cr>", 
        vim.tbl_extend("force", opts, { desc = "Cargo: Update" }))
      vim.keymap.set("n", "<leader>cx", "<cmd>CargoClean<cr>", 
        vim.tbl_extend("force", opts, { desc = "Cargo: Clean" }))
      vim.keymap.set("n", "<leader>cA", "<cmd>CargoAudit<cr>", 
        vim.tbl_extend("force", opts, { desc = "Cargo: Security Audit" }))
    end,
  },

  -- Enhanced which-key integration for Rust
  {
    "folke/which-key.nvim",
    optional = true,
    opts = function(_, opts)
      opts.spec = opts.spec or {}
      
      vim.list_extend(opts.spec, {
        { "<leader>r", group = "rust" },
        { "<leader>c", group = "cargo" },
        { "<leader>t", group = "test" },
        { "<leader>d", group = "debug" },
        
        -- Rust-specific groups
        { "<leader>rr", group = "run" },
        { "<leader>rt", group = "test" },
        { "<leader>rd", group = "debug" },
        { "<leader>rf", group = "format" },
        { "<leader>rc", group = "clippy" },
        
        -- Cargo groups
        { "<leader>cb", group = "build" },
        { "<leader>ct", group = "test" },
        { "<leader>cc", group = "check" },
        { "<leader>cd", group = "doc" },
        { "<leader>cf", group = "format" },
        { "<leader>cl", group = "lint" },
      })
      
      return opts
    end,
  },

  -- Project templates for common Rust patterns
  {
    "nvim-lua/plenary.nvim",
    config = function()
      -- Function to create project templates
      local function create_from_template()
        local templates = {
          "CLI Application",
          "Web Server (Axum)",
          "Library",
          "WebAssembly",
          "Async Application",
          "Game (Bevy)",
          "Desktop App (Tauri)",
        }
        
        vim.ui.select(templates, {
          prompt = "Select project template:",
        }, function(choice)
          if not choice then return end
          
          vim.ui.input({
            prompt = "Project name: ",
          }, function(name)
            if not name or name == "" then return end
            
            local template_configs = {
              ["CLI Application"] = {
                dependencies = { "clap", "anyhow", "serde" },
                main_content = [[use clap::Parser;
use anyhow::Result;

#[derive(Parser)]
#[command(author, version, about, long_about = None)]
struct Args {
    /// Name of the person to greet
    #[arg(short, long)]
    name: String,
}

fn main() -> Result<()> {
    let args = Args::parse();
    println!("Hello {}!", args.name);
    Ok(())
}]]
              },
              ["Web Server (Axum)"] = {
                dependencies = { "axum", "tokio", "serde", "anyhow" },
                main_content = [[use axum::{
    routing::{get, post},
    http::StatusCode,
    Json, Router,
};
use serde::{Deserialize, Serialize};

#[tokio::main]
async fn main() {
    let app = Router::new()
        .route("/", get(root))
        .route("/users", post(create_user));

    let listener = tokio::net::TcpListener::bind("0.0.0.0:3000").await.unwrap();
    axum::serve(listener, app).await.unwrap();
}

async fn root() -> &'static str {
    "Hello, World!"
}

async fn create_user(Json(payload): Json<CreateUser>) -> (StatusCode, Json<User>) {
    let user = User {
        id: 1337,
        username: payload.username,
    };

    (StatusCode::CREATED, Json(user))
}

#[derive(Deserialize)]
struct CreateUser {
    username: String,
}

#[derive(Serialize)]
struct User {
    id: u64,
    username: String,
}]]
              },
              -- Add more templates as needed
            }
            
            -- Create the project
            run_cargo_command("new", { name }, {
              on_complete = function(result, return_val)
                if return_val == 0 then
                  local config = template_configs[choice]
                  if config then
                    -- Add dependencies
                    for _, dep in ipairs(config.dependencies) do
                      run_cargo_command("add", { dep }, { terminal = false })
                    end
                    
                    -- Write main.rs content
                    if config.main_content then
                      local main_path = name .. "/src/main.rs"
                      vim.fn.writefile(vim.split(config.main_content, "\n"), main_path)
                    end
                  end
                  
                  vim.notify("Created " .. choice .. " project: " .. name)
                  vim.cmd("cd " .. name)
                  vim.cmd("edit src/main.rs")
                end
              end,
              terminal = false,
            })
          end)
        end)
      end
      
      vim.api.nvim_create_user_command("CargoTemplate", create_from_template, {
        desc = "Create project from template"
      })
      
      vim.keymap.set("n", "<leader>cN", create_from_template, {
        silent = true,
        desc = "Cargo: New from Template"
      })
    end,
  },
}