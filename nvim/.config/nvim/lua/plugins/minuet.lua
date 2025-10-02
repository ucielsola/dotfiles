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
            optional = {
              max_tokens = 512,
            },
          },
        },
        notify = "warn",
        throttle = 1000,
        debounce = 400,
        request_timeout = 3,
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
          },
        },
      },
    },
  },
}

-- API Key Setup:
-- Set ANTHROPIC_API_KEY environment variable in your shell:
-- export ANTHROPIC_API_KEY="your-api-key-here"
-- 
-- Or add to ~/.zshrc:
-- echo 'export ANTHROPIC_API_KEY="your-api-key"' >> ~/.zshrc
