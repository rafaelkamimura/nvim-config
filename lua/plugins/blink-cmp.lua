return {
  -- Override blink.cmp configuration to include Copilot
  {
    "saghen/blink.cmp",
    opts = function(_, opts)
      -- Add Copilot to the sources
      opts.sources = opts.sources or {}
      opts.sources.default = opts.sources.default or {}
      
      -- Add copilot to the list of sources
      table.insert(opts.sources.default, "copilot")
      
      -- Configure Copilot source
      opts.sources.providers = opts.sources.providers or {}
      opts.sources.providers.copilot = {
        name = "copilot",
        module = "blink-cmp-copilot",
        score_offset = 100, -- Higher priority than other sources
        async = true,
      }

      return opts
    end,
  },
}