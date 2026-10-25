vim.api.nvim_create_autocmd("User", {
  pattern = "VeryLazy",
  callback = function()
    vim.lsp.enable("gopls")
  end,
})

return {}
