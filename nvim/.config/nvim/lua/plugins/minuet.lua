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
              max_tokens = 256,
            },
          },
        },
        notify = "debug",
        throttle = 1000,
        debounce = 400,
        request_timeout = 5,
        context_window = 8000,
        -- Enable auto-completion through blink
        blink = {
          enable_auto_complete = true,
        },
      })
    end,
    keys = {
      -- Manual trigger for minuet completion
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
            timeout_ms = 5000,
          },
        },
      },
    },
  },
}
