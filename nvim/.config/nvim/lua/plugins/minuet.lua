return {
  {
    "milanglacier/minuet-ai.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    config = function()
      require("minuet").setup({
        provider = "gemini",
        provider_options = {
          gemini = {
            model = "gemini-2.0-flash-exp",
            stream = true,
            api_key = "GOOGLE_AI_API_KEY",
            optional = {
              generationConfig = {
                maxOutputTokens = 512, -- Increased from 128 for more complete suggestions
              },
            },
          },
        },
        notify = false,
        throttle = 1000, -- Slightly increased to avoid too many requests
        debounce = 500, -- Increased to let you type more before suggesting
        request_timeout = 5, -- More time for longer completions
        context_window = 12000, -- Increased from 4000 for better context understanding
        n_completions = 3, -- Back to 3 for more variety
      })
    end,
    keys = {
      {
        "<A-y>",
        function()
          require("blink-cmp").show({ providers = { "minuet" } })
        end,
        mode = "i",
        desc = "Trigger Minuet AI completion",
      },
    },
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
            timeout_ms = 5000, -- More time for better completions
          },
        },
      },
    },
  },
}
