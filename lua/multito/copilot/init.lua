local M = {}

function M.start(opts)
  return require("multito.copilot.lsp").start(opts)
end

function M.sign_in()
  return require("multito.copilot.auth").sign_in()
end

function M.sign_out()
  return require("multito.copilot.auth").sign_out()
end

return M
