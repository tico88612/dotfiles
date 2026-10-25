vim.api.nvim_create_autocmd("VimEnter", {
  group = vim.api.nvim_create_augroup("my_persistence_autoload", { clear = true }),
  nested = true,
  once = true,
  callback = function()
    local argc = vim.fn.argc(-1)
    if argc == 0 then
      vim.schedule(function()
        require("persistence").load()
      end)
    elseif argc == 1 then
      local arg = vim.fn.argv(0)
      if vim.fn.isdirectory(arg) == 1 then
        vim.cmd.cd(arg)
        vim.cmd("argdelete *")
        vim.schedule(function()
          require("persistence").load()
        end)
      end
    end
  end,
})

return {
  {
    "folke/persistence.nvim",
    lazy = false,
    opts = {},
  },
}