-- Package Manager Integration and Auto-imports
-- Support for npm, yarn, pnpm with enhanced import functionality
return {
  -- Package.json management and visualization
  {
    "vuki656/package-info.nvim",
    dependencies = { "MunifTanjim/nui.nvim" },
    event = { "BufRead package.json" },
    opts = {
      colors = {
        up_to_date = "#3C4048",
        outdated = "#d19a66",
        invalid = "#ee6d85",
      },
      icons = {
        enable = true,
        style = {
          up_to_date = "|  ",
          outdated = "|  ",
          invalid = "|  ",
        },
      },
      autostart = true,
      hide_up_to_date = false,
      hide_unstable_versions = false,
      package_manager = "npm", -- npm, yarn, pnpm
    },
    keys = {
      {
        "<leader>ns",
        function()
          require("package-info").show({ force = true })
        end,
        desc = "Show package versions",
        ft = "json",
      },
      {
        "<leader>nc",
        function()
          require("package-info").hide()
        end,
        desc = "Hide package versions",
        ft = "json",
      },
      {
        "<leader>nt",
        function()
          require("package-info").toggle()
        end,
        desc = "Toggle package versions",
        ft = "json",
      },
      {
        "<leader>nu",
        function()
          require("package-info").update()
        end,
        desc = "Update package on line",
        ft = "json",
      },
      {
        "<leader>nd",
        function()
          require("package-info").delete()
        end,
        desc = "Delete package on line",
        ft = "json",
      },
      {
        "<leader>ni",
        function()
          require("package-info").install()
        end,
        desc = "Install a new package",
        ft = "json",
      },
      {
        "<leader>np",
        function()
          require("package-info").change_version()
        end,
        desc = "Install a different package version",
        ft = "json",
      },
    },
  },

  -- Enhanced auto-imports and module resolution
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      -- Configure vtsls for better auto-imports
      if opts.servers and opts.servers.vtsls then
        opts.servers.vtsls.settings = opts.servers.vtsls.settings or {}
        opts.servers.vtsls.settings.vtsls = opts.servers.vtsls.settings.vtsls or {}
        
        -- Enhanced auto-import settings
        opts.servers.vtsls.settings.vtsls.autoUseWorkspaceTsdk = true
        
        opts.servers.vtsls.settings.typescript = opts.servers.vtsls.settings.typescript or {}
        opts.servers.vtsls.settings.typescript.suggest = {
          autoImports = true,
          completeFunctionCalls = true,
        }
        
        opts.servers.vtsls.settings.typescript.preferences = {
          importModuleSpecifier = "relative",
          includePackageJsonAutoImports = "on",
          allowTextChangesInNewFiles = true,
        }
        
        -- Code actions for auto-imports
        opts.servers.vtsls.settings.typescript.codeActions = {
          addMissingImports = true,
          removeUnusedImports = true,
          organizeImports = true,
        }
      end
      
      return opts
    end,
  },

  -- Import cost display
  {
    "barrett-ruth/import-cost.nvim",
    build = "sh install.sh npm",
    ft = { "javascript", "javascriptreact", "typescript", "typescriptreact", "vue", "svelte", "astro" },
    opts = {
      filetypes = {
        "javascript",
        "javascriptreact", 
        "typescript",
        "typescriptreact",
        "vue",
        "svelte",
        "astro",
      },
    },
    keys = {
      {
        "<leader>ic",
        function()
          require("import-cost").toggle()
        end,
        desc = "Toggle import cost",
      },
    },
  },

  -- Package manager detection and runner
  {
    "stevearc/overseer.nvim",
    optional = true,
    opts = function(_, opts)
      -- Detect package manager
      local function detect_package_manager()
        if vim.fn.filereadable("pnpm-lock.yaml") == 1 then
          return "pnpm"
        elseif vim.fn.filereadable("yarn.lock") == 1 then
          return "yarn"
        elseif vim.fn.filereadable("package-lock.json") == 1 then
          return "npm"
        else
          return "npm" -- default
        end
      end
      
      -- Store detected package manager
      vim.g.package_manager = detect_package_manager()
      
      -- Add package manager tasks
      opts.templates = opts.templates or {}
      vim.list_extend(opts.templates, {
        "user.npm_install",
        "user.npm_run",
        "user.package_update",
        "user.package_audit",
      })
      
      return opts
    end,
  },

  -- TypeScript import/export utilities
  {
    "dmmulroy/tsc.nvim",
    ft = { "typescript", "typescriptreact" },
    opts = {
      auto_open_qflist = true,
      auto_close_qflist = false,
      auto_focus_qflist = false,
      auto_start_watch_mode = false,
      use_trouble_qflist = true,
      run_as_monorepo = false,
    },
    keys = {
      {
        "<leader>tc",
        function()
          require("tsc").run()
        end,
        desc = "Run TypeScript compiler",
        ft = { "typescript", "typescriptreact" },
      },
      {
        "<leader>tw",
        function()
          require("tsc").run({ watch = true })
        end,
        desc = "Run TypeScript compiler in watch mode", 
        ft = { "typescript", "typescriptreact" },
      },
    },
  },

  -- Enhanced module path resolution
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      -- Configure path mapping for common aliases
      if opts.servers and opts.servers.vtsls then
        opts.servers.vtsls.settings = opts.servers.vtsls.settings or {}
        opts.servers.vtsls.settings.typescript = opts.servers.vtsls.settings.typescript or {}
        
        -- Path mapping for common aliases (@ -> src, ~ -> root, etc.)
        opts.servers.vtsls.settings.typescript.pathMapping = {
          ["@/*"] = { "./src/*" },
          ["~/*"] = { "./*" },
          ["components/*"] = { "./src/components/*" },
          ["utils/*"] = { "./src/utils/*" },
          ["types/*"] = { "./src/types/*" },
          ["assets/*"] = { "./src/assets/*" },
        }
      end
      
      return opts
    end,
  },

  -- Monorepo support
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      -- Enhanced monorepo support
      if opts.servers and opts.servers.vtsls then
        opts.servers.vtsls.root_dir = function(fname)
          local util = require("lspconfig.util")
          
          -- Look for workspace indicators first
          local workspace_root = util.root_pattern(
            "pnpm-workspace.yaml",
            "lerna.json",
            "nx.json",
            "rush.json"
          )(fname)
          
          if workspace_root then
            return workspace_root
          end
          
          -- Fall back to standard TypeScript project indicators
          return util.root_pattern(
            "tsconfig.json",
            "jsconfig.json",
            "package.json"
          )(fname)
        end
      end
      
      return opts
    end,
  },

  -- Workspace diagnostics for large projects
  {
    "artemave/workspace-diagnostics.nvim",
    ft = { "javascript", "javascriptreact", "typescript", "typescriptreact", "vue" },
    opts = {
      workspace_files = function()
        -- Get all TypeScript/JavaScript files in workspace
        return vim.fn.split(
          vim.fn.system("find " .. vim.fn.getcwd() .. " -type f -name '*.ts' -o -name '*.tsx' -o -name '*.js' -o -name '*.jsx' -o -name '*.vue' | grep -v node_modules"),
          "\n"
        )
      end,
    },
    keys = {
      {
        "<leader>wd",
        function()
          require("workspace-diagnostics").populate_workspace_diagnostics()
        end,
        desc = "Populate workspace diagnostics",
      },
    },
  },

  -- Package scripts runner
  {
    "neovim/nvim-lspconfig", 
    opts = function(_, opts)
      -- Create user commands for package management
      vim.api.nvim_create_user_command("PackageInstall", function()
        local pm = vim.g.package_manager or "npm"
        vim.cmd("terminal " .. pm .. " install")
      end, { desc = "Install packages" })
      
      vim.api.nvim_create_user_command("PackageUpdate", function()
        local pm = vim.g.package_manager or "npm"
        vim.cmd("terminal " .. pm .. " update")
      end, { desc = "Update packages" })
      
      vim.api.nvim_create_user_command("PackageAudit", function()
        local pm = vim.g.package_manager or "npm"
        vim.cmd("terminal " .. pm .. " audit")
      end, { desc = "Audit packages" })
      
      vim.api.nvim_create_user_command("PackageRun", function(opts)
        local pm = vim.g.package_manager or "npm"
        local script = opts.args
        if script == "" then
          script = vim.fn.input("Script name: ")
        end
        vim.cmd("terminal " .. pm .. " run " .. script)
      end, { 
        desc = "Run package script",
        nargs = "?",
        complete = function()
          -- Get scripts from package.json
          local package_json = vim.fn.getcwd() .. "/package.json"
          if vim.fn.filereadable(package_json) == 1 then
            local content = vim.fn.readfile(package_json)
            local json_str = table.concat(content, "\n")
            local scripts_match = string.match(json_str, '"scripts"%s*:%s*{([^}]*)}')
            if scripts_match then
              local scripts = {}
              for script in string.gmatch(scripts_match, '"([^"]+)"%s*:') do
                table.insert(scripts, script)
              end
              return scripts
            end
          end
          return {}
        end,
      })
      
      return opts
    end,
  },

  -- Enhanced which-key for package management
  {
    "folke/which-key.nvim",
    optional = true,
    opts = {
      defaults = {
        ["<leader>n"] = { name = "+npm/package" },
        ["<leader>p"] = { name = "+project" },
        ["<leader>pa"] = { name = "+package audit" },
        ["<leader>pi"] = { name = "+package install" },
        ["<leader>pr"] = { name = "+package run" },
        ["<leader>pu"] = { name = "+package update" },
      },
    },
  },

  -- Mason tool installer for package management tools
  {
    "williamboman/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, {
        "typescript-language-server",
        "vtsls",
        "eslint-lsp",
        "json-lsp",
      })
    end,
  },
}