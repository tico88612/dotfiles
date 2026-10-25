local term_program = vim.env.TERM_PROGRAM
local force_kitty_graphics = term_program == "iTerm.app" or term_program == "herdr" or vim.env.HERDR_ENV == "1"

return {
  {
    "folke/snacks.nvim",
    opts = {
      image = {
        enabled = true,
        -- Snacks does not currently detect iTerm2 or Herdr even though both
        -- support the Kitty graphics protocol.
        force = force_kitty_graphics,
        doc = {
          enabled = true,
          inline = true,
          float = true,
          max_width = 80,
          max_height = 40,
        },
      },
    },
  },
}
