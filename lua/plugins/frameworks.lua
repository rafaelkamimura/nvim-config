-- Framework-specific configurations for React, Vue, Next.js, Svelte
-- Enhanced support for modern JavaScript/TypeScript frameworks
return {
  -- React support
  {
    "napmn/react-extract.nvim",
    ft = { "javascriptreact", "typescriptreact" },
    opts = {},
    keys = {
      {
        "<leader>re",
        function()
          require("react-extract").extract_to_new_file()
        end,
        desc = "Extract component to new file",
        ft = { "javascriptreact", "typescriptreact" },
      },
      {
        "<leader>rc",
        function()
          require("react-extract").extract_to_current_file()
        end,
        desc = "Extract component to current file",
        ft = { "javascriptreact", "typescriptreact" },
      },
    },
  },

  -- Vue.js support
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      -- Ensure volar is configured for Vue.js
      opts.servers = opts.servers or {}
      opts.servers.volar = {
        filetypes = { "vue" },
        init_options = {
          vue = {
            hybridMode = false, -- Use Volar for all Vue features
          },
        },
        settings = {
          vue = {
            complete = {
              casing = {
                tags = "kebab",
                props = "camel",
              },
            },
          },
          typescript = {
            inlayHints = {
              enumMemberValues = { enabled = true },
              functionLikeReturnTypes = { enabled = true },
              propertyDeclarationTypes = { enabled = true },
              parameterTypes = { enabled = true },
              variableTypes = { enabled = true },
            },
          },
        },
      }
      
      -- Configure TypeScript Language Server for Vue support
      if opts.servers.vtsls then
        opts.servers.vtsls.filetypes = opts.servers.vtsls.filetypes or {}
        vim.list_extend(opts.servers.vtsls.filetypes, { "vue" })
        
        -- Configure Vue TypeScript plugin
        opts.servers.vtsls.init_options = opts.servers.vtsls.init_options or {}
        opts.servers.vtsls.init_options.plugins = opts.servers.vtsls.init_options.plugins or {}
        table.insert(opts.servers.vtsls.init_options.plugins, {
          name = "@vue/typescript-plugin",
          location = vim.fn.stdpath("data") .. "/mason/packages/vue-language-server/node_modules/@vue/language-server",
          languages = { "vue" },
        })
      end
      
      return opts
    end,
  },

  -- Enhanced Emmet support for HTML/JSX/Vue
  {
    "mattn/emmet-vim",
    ft = { "html", "css", "javascript", "javascriptreact", "typescript", "typescriptreact", "vue", "svelte", "astro" },
    config = function()
      vim.g.user_emmet_leader_key = "<C-z>"
      vim.g.user_emmet_settings = {
        javascript = {
          extends = "jsx",
        },
        typescript = {
          extends = "tsx",
        },
        vue = {
          extends = "html",
          default_attributes = {
            option = { value = nil },
            textarea = { id = nil, name = nil, cols = "10", rows = "10" },
          },
        },
      }
    end,
  },

  -- Astro support
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      opts.servers = opts.servers or {}
      opts.servers.astro = {
        filetypes = { "astro" },
        root_dir = function(fname)
          return require("lspconfig.util").root_pattern("astro.config.*", "package.json")(fname)
        end,
      }
      return opts
    end,
  },

  -- Svelte support
  {
    "neovim/nvim-lspconfig", 
    opts = function(_, opts)
      opts.servers = opts.servers or {}
      opts.servers.svelte = {
        filetypes = { "svelte" },
        settings = {
          svelte = {
            plugin = {
              html = { completions = { enable = true, emmet = false } },
              svelte = { completions = { enable = true, emmet = false } },
              css = { completions = { enable = true, emmet = true } },
            },
          },
        },
      }
      return opts
    end,
  },

  -- GraphQL support
  {
    "jparise/vim-graphql",
    ft = { "graphql", "gql", "typescriptreact", "javascriptreact" },
  },

  -- Enhanced treesitter for frameworks
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      if type(opts.ensure_installed) == "table" then
        vim.list_extend(opts.ensure_installed, {
          "vue",
          "astro", 
          "svelte",
          "graphql",
          "styled",
          "css",
          "scss",
          "html",
        })
      end
      
      -- Enhanced highlighting for embedded languages
      opts.highlight = opts.highlight or {}
      opts.highlight.additional_vim_regex_highlighting = false
      
      return opts
    end,
  },

  -- Mason tool installer for framework tools
  {
    "williamboman/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, {
        -- Vue.js tools
        "vue-language-server",
        
        -- Astro tools
        "@astrojs/language-server",
        
        -- Svelte tools
        "svelte-language-server",
        
        -- GraphQL tools
        "graphql-language-service-cli",
      })
    end,
  },

  -- Framework-specific snippets
  {
    "rafamadriz/friendly-snippets",
    config = function()
      require("luasnip.loaders.from_vscode").lazy_load()
      
      -- Load additional framework snippets
      require("luasnip.loaders.from_vscode").lazy_load({
        paths = { vim.fn.stdpath("data") .. "/lazy/friendly-snippets" },
      })
    end,
  },

  -- Next.js specific support
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      -- Next.js often uses the same TypeScript setup as React
      -- but we can add specific configurations if needed
      
      -- Auto-detect Next.js projects and adjust settings
      local function is_nextjs_project()
        local package_json = vim.fn.getcwd() .. "/package.json"
        if vim.fn.filereadable(package_json) == 1 then
          local content = vim.fn.readfile(package_json)
          local json_str = table.concat(content, "\n")
          return string.find(json_str, '"next"') ~= nil
        end
        return false
      end
      
      -- Enhance vtsls configuration for Next.js
      if opts.servers and opts.servers.vtsls and is_nextjs_project() then
        opts.servers.vtsls.settings = opts.servers.vtsls.settings or {}
        opts.servers.vtsls.settings.typescript = opts.servers.vtsls.settings.typescript or {}
        
        -- Next.js specific TypeScript settings
        opts.servers.vtsls.settings.typescript.preferences = {
          includePackageJsonAutoImports = "on",
          importModuleSpecifier = "relative",
        }
      end
      
      return opts
    end,
  },

  -- Styled components support
  {
    "styled-components/vim-styled-components",
    ft = { "javascriptreact", "typescriptreact" },
  },

  -- React hooks linting and refactoring
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      -- Configure ESLint for React hooks rules
      if opts.servers and opts.servers.eslint then
        opts.servers.eslint.settings = opts.servers.eslint.settings or {}
        opts.servers.eslint.settings.rules = opts.servers.eslint.settings.rules or {}
        
        -- React hooks specific rules
        opts.servers.eslint.settings.rules["react-hooks/rules-of-hooks"] = "error"
        opts.servers.eslint.settings.rules["react-hooks/exhaustive-deps"] = "warn"
      end
      
      return opts
    end,
  },

  -- Auto-import enhancements for frameworks
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      -- Enhanced auto-import settings for framework development
      if opts.servers and opts.servers.vtsls then
        opts.servers.vtsls.settings = opts.servers.vtsls.settings or {}
        opts.servers.vtsls.settings.typescript = opts.servers.vtsls.settings.typescript or {}
        
        -- Enhanced import suggestions
        opts.servers.vtsls.settings.typescript.suggest = {
          autoImports = true,
          completeFunctionCalls = true,
        }
        
        -- Auto-import preferences for common frameworks
        opts.servers.vtsls.settings.typescript.preferences = {
          importModuleSpecifier = "relative",
          includePackageJsonAutoImports = "on",
        }
      end
      
      return opts
    end,
  },

  -- Framework detection and project setup
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      -- Auto-detect framework and adjust configurations accordingly
      local function detect_framework()
        local package_json = vim.fn.getcwd() .. "/package.json"
        if vim.fn.filereadable(package_json) == 1 then
          local content = vim.fn.readfile(package_json)
          local json_str = table.concat(content, "\n")
          
          if string.find(json_str, '"react"') then
            return "react"
          elseif string.find(json_str, '"vue"') then
            return "vue"
          elseif string.find(json_str, '"@angular/core"') then
            return "angular"
          elseif string.find(json_str, '"svelte"') then
            return "svelte"
          elseif string.find(json_str, '"astro"') then
            return "astro"
          elseif string.find(json_str, '"next"') then
            return "nextjs"
          elseif string.find(json_str, '"nuxt"') then
            return "nuxt"
          end
        end
        return "vanilla"
      end
      
      -- Store detected framework for use in other configurations
      vim.g.detected_framework = detect_framework()
      
      return opts
    end,
  },

  -- Framework-specific keymaps and commands
  {
    "folke/which-key.nvim",
    optional = true,
    opts = {
      defaults = {
        ["<leader>f"] = { name = "+framework" },
        ["<leader>fr"] = { name = "+react" },
        ["<leader>fv"] = { name = "+vue" },
        ["<leader>fn"] = { name = "+next" },
        ["<leader>fa"] = { name = "+astro" },
        ["<leader>fs"] = { name = "+svelte" },
      },
    },
  },
}