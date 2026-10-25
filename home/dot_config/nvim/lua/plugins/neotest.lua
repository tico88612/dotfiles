return {
  {
    "nvim-neotest/neotest",
    opts = {
      discovery = {
        enabled = false,
      },
      adapters = {
        ["neotest-golang"] = {
          warn_test_name_dupes = false,
        },
      },
    },
  },
}
