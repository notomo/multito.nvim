local M = {}

function M.info(message, attributes)
  vim.notify(("[multito] %s%s"):format(message, attributes and vim.inspect(attributes) or ""))
end

function M.warn(err)
  vim.notify(("[multito] %s"):format(err), vim.log.levels.WARN)
end

return M
