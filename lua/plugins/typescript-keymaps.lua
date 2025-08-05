-- Enhanced TypeScript/JavaScript Keymaps and User Commands
-- Comprehensive keybindings for modern web development
return {
  -- Which-key configuration for better key discovery
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      defaults = {
        mode = { "n", "v" },
        ["<leader>c"] = { name = "+code" },
        ["<leader>ca"] = { name = "+code action" },
        ["<leader>cf"] = { name = "+format/fix" },
        ["<leader>ci"] = { name = "+import" },
        ["<leader>cr"] = { name = "+refactor" },
        ["<leader>ct"] = { name = "+typescript" },
        ["<leader>d"] = { name = "+debug" },
        ["<leader>f"] = { name = "+framework" },
        ["<leader>g"] = { name = "+git/goto" },
        ["<leader>l"] = { name = "+lsp" },
        ["<leader>n"] = { name = "+npm/node" },
        ["<leader>p"] = { name = "+project" },
        ["<leader>r"] = { name = "+run/refactor" },
        ["<leader>s"] = { name = "+search" },
        ["<leader>t"] = { name = "+test/toggle" },
        ["<leader>w"] = { name = "+workspace" },
        ["<leader>x"] = { name = "+diagnostics/quickfix" },
      },
    },
    config = function(_, opts)
      local wk = require("which-key")
      wk.setup(opts)
      wk.register(opts.defaults)
    end,
  },

  -- Enhanced LSP keymaps specifically for TypeScript/JavaScript
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      -- Custom on_attach function for TypeScript/JavaScript specific keymaps
      local on_attach = function(client, bufnr)
        local map = function(keys, func, desc)
          vim.keymap.set("n", keys, func, { buffer = bufnr, desc = desc })
        end

        local map_visual = function(keys, func, desc)
          vim.keymap.set("v", keys, func, { buffer = bufnr, desc = desc })
        end

        -- Enhanced navigation
        map("gd", vim.lsp.buf.definition, "Goto Definition")
        map("gD", vim.lsp.buf.declaration, "Goto Declaration")
        map("gi", vim.lsp.buf.implementation, "Goto Implementation")
        map("gr", vim.lsp.buf.references, "References")
        map("gt", vim.lsp.buf.type_definition, "Type Definition")

        -- Documentation and hover
        map("K", vim.lsp.buf.hover, "Hover Documentation")
        map("<C-k>", vim.lsp.buf.signature_help, "Signature Help")

        -- Code actions and refactoring
        map("<leader>ca", vim.lsp.buf.code_action, "Code Action")
        map("<leader>cr", vim.lsp.buf.rename, "Rename Symbol")
        map_visual("<leader>ca", vim.lsp.buf.code_action, "Code Action")

        -- TypeScript specific actions
        if client.name == "vtsls" or client.name == "typescript-tools" then
          map("<leader>co", function()
            vim.lsp.buf.execute_command({
              command = "typescript.organizeImports",
              arguments = { vim.api.nvim_buf_get_name(0) },
            })
          end, "Organize Imports")

          map("<leader>cM", function()
            vim.lsp.buf.execute_command({
              command = "typescript.addMissingImports",
              arguments = { vim.api.nvim_buf_get_name(0) },
            })
          end, "Add Missing Imports")

          map("<leader>cu", function()
            vim.lsp.buf.execute_command({
              command = "typescript.removeUnusedImports",
              arguments = { vim.api.nvim_buf_get_name(0) },
            })
          end, "Remove Unused Imports")

          map("<leader>cD", function()
            vim.lsp.buf.execute_command({
              command = "typescript.fixAll",
              arguments = { vim.api.nvim_buf_get_name(0) },
            })
          end, "Fix All")

          map("<leader>cV", function()
            vim.lsp.buf.execute_command({ command = "typescript.selectTypeScriptVersion" })
          end, "Select TS Version")

          map("<leader>cR", function()
            vim.lsp.buf.execute_command({
              command = "typescript.renameFile",
              arguments = {
                vim.api.nvim_buf_get_name(0),
                vim.fn.input("New name: ", vim.fn.expand("%:t")),
              },
            })
          end, "Rename File")

          map("<leader>ctg", function()
            vim.lsp.buf.execute_command({
              command = "typescript.goToSourceDefinition",
              arguments = { vim.api.nvim_buf_get_name(0), vim.lsp.util.make_position_params().position },
            })
          end, "Go to Source Definition")

          map("<leader>ctf", function()
            vim.lsp.buf.execute_command({
              command = "typescript.findAllFileReferences",
              arguments = { vim.api.nvim_buf_get_name(0) },
            })
          end, "Find All File References")
        end

        -- Diagnostics
        map("<leader>e", vim.diagnostic.open_float, "Show Diagnostic")
        map("[d", vim.diagnostic.goto_prev, "Previous Diagnostic")
        map("]d", vim.diagnostic.goto_next, "Next Diagnostic")
        map("<leader>q", vim.diagnostic.setloclist, "Diagnostic Quickfix")

        -- Workspace
        map("<leader>wa", vim.lsp.buf.add_workspace_folder, "Add Workspace Folder")
        map("<leader>wr", vim.lsp.buf.remove_workspace_folder, "Remove Workspace Folder")
        map("<leader>wl", function()
          print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
        end, "List Workspace Folders")

        -- Inlay hints toggle (for Neovim 0.10+)
        if vim.lsp.inlay_hint then
          map("<leader>th", function()
            vim.lsp.inlay_hint.enable(0, not vim.lsp.inlay_hint.is_enabled())
          end, "Toggle Inlay Hints")
        end
      end

      -- Apply the enhanced on_attach to TypeScript/JavaScript servers
      if opts.servers then
        for server_name, server_opts in pairs(opts.servers) do
          if server_name == "vtsls" or server_name == "eslint" or server_name == "jsonls" then
            server_opts.on_attach = on_attach
          end
        end
      end

      return opts
    end,
  },

  -- Additional TypeScript/JavaScript specific commands
  {
    "neovim/nvim-lspconfig",
    config = function()
      -- Create user commands for common TypeScript operations
      vim.api.nvim_create_user_command("TSOrganizeImports", function()
        vim.lsp.buf.execute_command({
          command = "typescript.organizeImports",
          arguments = { vim.api.nvim_buf_get_name(0) },
        })
      end, { desc = "Organize TypeScript imports" })

      vim.api.nvim_create_user_command("TSAddMissingImports", function()
        vim.lsp.buf.execute_command({
          command = "typescript.addMissingImports",
          arguments = { vim.api.nvim_buf_get_name(0) },
        })
      end, { desc = "Add missing TypeScript imports" })

      vim.api.nvim_create_user_command("TSRemoveUnusedImports", function()
        vim.lsp.buf.execute_command({
          command = "typescript.removeUnusedImports",
          arguments = { vim.api.nvim_buf_get_name(0) },
        })
      end, { desc = "Remove unused TypeScript imports" })

      vim.api.nvim_create_user_command("TSFixAll", function()
        vim.lsp.buf.execute_command({
          command = "typescript.fixAll",
          arguments = { vim.api.nvim_buf_get_name(0) },
        })
      end, { desc = "Fix all TypeScript issues" })

      vim.api.nvim_create_user_command("TSSelectVersion", function()
        vim.lsp.buf.execute_command({ command = "typescript.selectTypeScriptVersion" })
      end, { desc = "Select TypeScript version" })

      vim.api.nvim_create_user_command("TSRenameFile", function()
        local current_name = vim.fn.expand("%:t")
        local new_name = vim.fn.input("New name: ", current_name)
        if new_name ~= "" and new_name ~= current_name then
          vim.lsp.buf.execute_command({
            command = "typescript.renameFile",
            arguments = { vim.api.nvim_buf_get_name(0), new_name },
          })
        end
      end, { desc = "Rename TypeScript file" })

      -- Package.json script runner
      vim.api.nvim_create_user_command("NpmRun", function(opts)
        local script = opts.args
        if script == "" then
          script = vim.fn.input("Script name: ")
        end
        local pm = vim.g.package_manager or "npm"
        vim.cmd("terminal " .. pm .. " run " .. script)
      end, {
        desc = "Run npm script",
        nargs = "?",
        complete = function()
          local scripts = {}
          local package_json = vim.fn.getcwd() .. "/package.json"
          if vim.fn.filereadable(package_json) == 1 then
            local content = vim.fn.readfile(package_json)
            local json_str = table.concat(content, "\n")
            local scripts_section = string.match(json_str, '"scripts"%s*:%s*{([^}]*)}')
            if scripts_section then
              for script in string.gmatch(scripts_section, '"([^"]+)"%s*:') do
                table.insert(scripts, script)
              end
            end
          end
          return scripts
        end,
      })

      -- Project type detection command
      vim.api.nvim_create_user_command("DetectProject", function()
        local package_json = vim.fn.getcwd() .. "/package.json"
        if vim.fn.filereadable(package_json) == 1 then
          local content = vim.fn.readfile(package_json)
          local json_str = table.concat(content, "\n")
          
          local project_types = {}
          if string.find(json_str, '"react"') then table.insert(project_types, "React") end
          if string.find(json_str, '"vue"') then table.insert(project_types, "Vue.js") end
          if string.find(json_str, '"@angular/core"') then table.insert(project_types, "Angular") end
          if string.find(json_str, '"svelte"') then table.insert(project_types, "Svelte") end
          if string.find(json_str, '"astro"') then table.insert(project_types, "Astro") end
          if string.find(json_str, '"next"') then table.insert(project_types, "Next.js") end
          if string.find(json_str, '"nuxt"') then table.insert(project_types, "Nuxt.js") end
          if string.find(json_str, '"express"') then table.insert(project_types, "Express") end
          if string.find(json_str, '"fastify"') then table.insert(project_types, "Fastify") end
          
          local pm_type = "npm"
          if vim.fn.filereadable("pnpm-lock.yaml") == 1 then pm_type = "pnpm"
          elseif vim.fn.filereadable("yarn.lock") == 1 then pm_type = "yarn"
          end
          
          print("Project type: " .. (table.concat(project_types, ", ") or "JavaScript/TypeScript"))
          print("Package manager: " .. pm_type)
        else
          print("No package.json found")
        end
      end, { desc = "Detect project type and package manager" })

      -- Format and lint shortcuts
      vim.api.nvim_create_user_command("FormatAndLint", function()
        vim.lsp.buf.format({ async = true })
        vim.defer_fn(function()
          vim.lsp.buf.code_action({
            filter = function(action)
              return action.kind == "source.fixAll.eslint"
            end,
            apply = true,
          })
        end, 100)
      end, { desc = "Format and lint current buffer" })
    end,
  },

  -- Quick access to common files
  {
    "nvim-telescope/telescope.nvim",
    keys = {
      {
        "<leader>fp",
        function()
          require("telescope.builtin").find_files({
            prompt_title = "Package Files",
            cwd = vim.fn.getcwd(),
            find_command = {
              "find",
              ".",
              "-name",
              "package.json",
              "-o",
              "-name",
              "tsconfig.json",
              "-o",
              "-name",
              "jsconfig.json",
              "-o",
              "-name",
              ".eslintrc*",
              "-o", 
              "-name",
              "prettier.config.*",
              "-o",
              "-name",
              ".prettierrc*",
              "-o",
              "-name",
              "vite.config.*",
              "-o",
              "-name",
              "vitest.config.*",
              "-o",
              "-name",
              "jest.config.*",
            },
          })
        end,
        desc = "Find package config files",
      },
      {
        "<leader>fT",
        function()
          require("telescope.builtin").find_files({
            prompt_title = "TypeScript Files",
            cwd = vim.fn.getcwd(),
            find_command = { "fd", "-e", "ts", "-e", "tsx", "-e", "d.ts" },
          })
        end,
        desc = "Find TypeScript files",
      },
      {
        "<leader>fJ",
        function()
          require("telescope.builtin").find_files({
            prompt_title = "JavaScript Files",
            cwd = vim.fn.getcwd(),
            find_command = { "fd", "-e", "js", "-e", "jsx", "-e", "mjs", "-e", "cjs" },
          })
        end,
        desc = "Find JavaScript files",
      },
    },
  },

  -- Enhanced autocmds for TypeScript/JavaScript development
  {
    "neovim/nvim-lspconfig",
    config = function()
      local augroup = vim.api.nvim_create_augroup("TypeScriptJavaScript", { clear = true })
      
      -- Auto-organize imports on save for TypeScript/JavaScript files
      vim.api.nvim_create_autocmd("BufWritePre", {
        group = augroup,
        pattern = { "*.ts", "*.tsx", "*.js", "*.jsx" },
        callback = function()
          if vim.g.auto_organize_imports ~= false then
            local clients = vim.lsp.get_active_clients({ bufnr = 0 })
            for _, client in ipairs(clients) do
              if client.name == "vtsls" then
                vim.lsp.buf.execute_command({
                  command = "typescript.organizeImports",
                  arguments = { vim.api.nvim_buf_get_name(0) },
                })
                break
              end
            end
          end
        end,
        desc = "Auto-organize imports on save",
      })

      -- Auto-format on save
      vim.api.nvim_create_autocmd("BufWritePre", {
        group = augroup,
        pattern = { "*.ts", "*.tsx", "*.js", "*.jsx", "*.vue", "*.json" },
        callback = function()
          if vim.g.auto_format ~= false then
            vim.lsp.buf.format({ async = false })
          end
        end,
        desc = "Auto-format on save",
      })

      -- Set specific options for TypeScript/JavaScript files
      vim.api.nvim_create_autocmd("FileType", {
        group = augroup,
        pattern = { "typescript", "typescriptreact", "javascript", "javascriptreact" },
        callback = function()
          vim.opt_local.shiftwidth = 2
          vim.opt_local.tabstop = 2
          vim.opt_local.softtabstop = 2
          vim.opt_local.expandtab = true
        end,
        desc = "Set TypeScript/JavaScript specific options",
      })

      -- Update package manager variable when changing directories
      vim.api.nvim_create_autocmd("DirChanged", {
        group = augroup,
        callback = function()
          local function detect_package_manager()
            if vim.fn.filereadable("pnpm-lock.yaml") == 1 then
              return "pnpm"
            elseif vim.fn.filereadable("yarn.lock") == 1 then
              return "yarn"
            elseif vim.fn.filereadable("package-lock.json") == 1 then
              return "npm"
            else
              return "npm"
            end
          end
          vim.g.package_manager = detect_package_manager()
        end,
        desc = "Update package manager detection",
      })
    end,
  },

  -- Toggle commands for development workflow
  {
    "neovim/nvim-lspconfig",
    config = function()
      -- Toggle auto-organize imports
      vim.api.nvim_create_user_command("ToggleAutoOrganizeImports", function()
        vim.g.auto_organize_imports = not vim.g.auto_organize_imports
        print("Auto-organize imports: " .. (vim.g.auto_organize_imports and "enabled" or "disabled"))
      end, { desc = "Toggle auto-organize imports on save" })

      -- Toggle auto-format
      vim.api.nvim_create_user_command("ToggleAutoFormat", function()
        vim.g.auto_format = not vim.g.auto_format
        print("Auto-format: " .. (vim.g.auto_format and "enabled" or "disabled"))
      end, { desc = "Toggle auto-format on save" })
    end,
  },
}