return {
  {
    "folke/sidekick.nvim",
    lazy = false,
    dependencies = { "folke/snacks.nvim" },
    opts = {
      -- Codex CLI works independently from Copilot's Next Edit Suggestions.
      nes = { enabled = false },
      cli = {
        win = {
          split = { width = 0.30 },
        },
        tools = {
          codex = {},
        },
      },
    },
    keys = {
      {
        "<leader>ac",
        function()
          require("sidekick.cli").toggle({ name = "codex", focus = true })
        end,
        desc = "Codex: Toggle",
      },
      {
        "<leader>cf",
        function()
          require("sidekick.cli").focus({ name = "codex" })
        end,
        mode = { "n", "t", "i", "x" },
        desc = "Codex: Focus",
      },
      {
        "<leader>cd",
        function()
          require("sidekick.cli").close({ name = "codex" })
        end,
        desc = "Codex: Detach session",
      },
      {
        "<leader>cs",
        function()
          require("sidekick.cli").send({ name = "codex", msg = "{selection}" })
        end,
        mode = "x",
        desc = "Codex: Send selection",
      },
      {
        "<leader>ca",
        function()
          require("sidekick.cli").send({ name = "codex", msg = "{this}" })
        end,
        mode = { "n", "x" },
        desc = "Codex: Send context",
      },
    },
  },
}
