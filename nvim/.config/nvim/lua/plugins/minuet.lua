return {
  {
    "milanglacier/minuet-ai.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    config = function()
      require("minuet").setup({
        provider = "claude",
        provider_options = {
          claude = {
            model = "claude-3-5-haiku-20241022",
            system = nil, -- Use default
            stream = true,
            api_key = "ANTHROPIC_API_KEY",
            optional = {
              max_tokens = 256, -- Reduced for faster response
            },
          },
        },
        notify = "debug", -- Changed from "warn" to "debug" for more info
        throttle = 1000,
        debounce = 400,
        request_timeout = 5, -- Increased from 3 to 5 seconds
        context_window = 8000, -- Reduced to avoid sending too much context
      })
    end,
  },
  {
    "saghen/blink.cmp",
    optional = true,
    opts = {
      sources = {
        default = { "lsp", "path", "snippets", "buffer", "minuet" },
        providers = {
          minuet = {
            name = "minuet",
            module = "minuet.blink",
            score_offset = 50,
            async = true,
            timeout_ms = 5000,
          },
        },
      },
    },
  },
}
