local M = {}

--- Open panel and show completion items.
--- @param opts {offset:integer?,open:fun(bufnr:integer)}?
function M.completion(opts)
  opts = opts or {}
  opts.offset = opts.offset or 0
  opts.open = opts.open
    or function(bufnr)
      vim.api.nvim_open_win(bufnr, true, {
        split = "left",
        vertical = true,
      })
    end

  local window_id = vim.api.nvim_get_current_win()
  local bufnr = vim.api.nvim_win_get_buf(window_id)
  local method = "textDocument/copilotPanelCompletion"

  local client = require("multito.copilot.lsp").get_client({
    method = method,
    bufnr = bufnr,
  })
  if type(client) == "string" then
    local err = client
    require("multito.lib.message").warn(err)
    return
  end

  local position_params = vim.lsp.util.make_position_params(window_id, client.offset_encoding)
  local partial_result_token = tostring(vim.uv.hrtime())
  local params = vim.tbl_extend("force", { partialResultToken = partial_result_token }, position_params)

  local observable = require("multito.copilot.lsp").request_progress({
    method = method,
    params = params,
    bufnr = bufnr,
    partial_result_token = partial_result_token,
    client_id = client.id,
  })

  local panel = require("multito.copilot.panel.view").open({
    source_bufnr = bufnr,
    client_id = client.id,
    partial_result_token = partial_result_token,
    open = opts.open,
  })

  observable:subscribe({
    next = function(progress)
      panel:add(progress)
      panel:render(1 + opts.offset)
    end,
    complete = function()
      panel:done()
    end,
    error = function(err)
      require("multito.lib.message").warn(err)
    end,
  })
end

--- Show completion item.
--- @param opts {bufnr:integer?,offset:integer?}?
function M.show_item(opts)
  opts = opts or {}
  opts.offset = opts.offset or 1
  opts.bufnr = opts.bufnr or vim.api.nvim_get_current_buf()

  local panel = require("multito.copilot.panel.view").from(opts.bufnr)
  if not panel then
    return
  end

  panel:show_item(opts.offset)
end

--- Accepts completion item.
--- @param opts {bufnr:integer?}?
function M.accept(opts)
  opts = opts or {}
  opts.bufnr = opts.bufnr or vim.api.nvim_get_current_buf()

  local panel = require("multito.copilot.panel.view").from(opts.bufnr)
  if not panel then
    return require("multito.vendor.promise").resolve()
  end

  return panel:accept()
end

--- @param opts {bufnr:integer?}?
function M.get(opts)
  opts = opts or {}
  opts.bufnr = opts.bufnr or vim.api.nvim_get_current_buf()

  local panel = require("multito.copilot.panel.view").from(opts.bufnr)
  if not panel then
    return
  end

  return panel:get()
end

return M
