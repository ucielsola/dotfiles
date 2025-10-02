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
            stream = true,
            api_key = "ANTHROPIC_API_KEY",
            optional = {
              max_tokens = 128, -- Reduced from 256 for faster response
              stop_sequences = { "\n\n" }, -- Stop at double newline for quicker results
            },
          },
        },
        notify = false, -- Disable all notifications
        throttle = 500, -- Reduced from 1000ms for faster triggering
        debounce = 300, -- Reduced from 400ms for quicker response
        request_timeout = 4, -- Slightly reduced from 5
        context_window = 4000, -- Reduced from 8000 for faster processing
        n_completions = 2, -- Reduced from 3 to get results faster
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
            timeout_ms = 4000, -- Reduced from 5000
          },
        },
      },
    },
  },
}
