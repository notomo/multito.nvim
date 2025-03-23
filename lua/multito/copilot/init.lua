local M = {}

--- Create lsp client and start server. This wraps |vim.lsp.start()|.
--- @param opts table?
function M.start(opts)
  return require("multito.copilot.lsp").start(opts)
end

--- Sign in GitHub Copilot.
function M.sign_in()
  return require("multito.copilot.auth").sign_in()
end

--- Sign out GitHub Copilot.
function M.sign_out()
  return require("multito.copilot.auth").sign_out()
end

return M
