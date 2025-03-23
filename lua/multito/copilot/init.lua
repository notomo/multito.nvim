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

function M.inline_completion(opts)
  return require("multito.copilot.inline").completion(opts)
end

function M.inline_accept(opts)
  return require("multito.copilot.inline").accept(opts)
end

function M.inline_clear(opts)
  require("multito.copilot.inline").clear(opts)
end

return M
