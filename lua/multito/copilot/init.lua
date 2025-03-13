local M = {}

function M.config(config)
  require("multito.copilot.lsp").config(config)
end

function M.sign_in()
  return require("multito.copilot.auth").sign_in()
end

function M.sign_out()
  return require("multito.copilot.auth").sign_out()
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

function M.panel_get(opts)
  return require("multito.copilot.panel").get(opts)
end

return M
