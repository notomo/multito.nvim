local setup_highlight_groups = function()
  local highlightlib = require("multito.vendor.misclib.highlight")
  return {
    MultitoInlineCompletionItem = highlightlib.link("MultitoInlineCompletionItem", "NormalFloat"),
  }
end

local group = vim.api.nvim_create_augroup("multito.highlight_group", {})
vim.api.nvim_create_autocmd({ "ColorScheme" }, {
  group = group,
  pattern = { "*" },
  callback = function()
    setup_highlight_groups()
  end,
})

return setup_highlight_groups()
