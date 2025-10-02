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
            api_key = "GEMINI_API_KEY", -- Set as: export GEMINI_API_KEY="your-key"
            optional = {
              generationConfig = {
                maxOutputTokens = 128,
              },
            },
          },
        },
        notify = false,
        throttle = 500,
        debounce = 300,
        request_timeout = 3, -- Gemini is faster, reduced from 4
        context_window = 4000,
        n_completions = 2,
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
            timeout_ms = 3000,
          },
        },
      },
    },
  },
}
