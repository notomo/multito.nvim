local M = {}

function M.config(config)
  require("multito.copilot.lsp").config(config)
end

function M.sign_in()
  require("multito.copilot.auth").sign_in()
end

function M.sign_out()
  require("multito.copilot.auth").sign_out()
end

function M.panel_completion(opts)
  require("multito.copilot.panel").completion(opts)
end

function M.panel_show_item(opts)
  require("multito.copilot.panel").show_item(opts)
end

function M.panel_accept(opts)
  require("multito.copilot.panel").accept(opts)
end

return M
