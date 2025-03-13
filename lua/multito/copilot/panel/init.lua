local M = {}

function M.completion(raw_opts)
  raw_opts = raw_opts or {}
  raw_opts.offset = raw_opts.offset or 1

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
    client = client,
    partial_result_token = partial_result_token,
  })

  observable:subscribe({
    next = function(progress)
      panel:add(progress)
      panel:render(1 + raw_opts.offset)
    end,
    complete = function()
      panel:done()
    end,
    error = function(err)
      require("multito.lib.message").warn(err)
    end,
  })
end

function M.show_item(raw_opts)
  raw_opts = raw_opts or {}
  raw_opts.offset = raw_opts.offset or 1
  raw_opts.bufnr = raw_opts.bufnr or vim.api.nvim_get_current_buf()

  local panel = require("multito.copilot.panel.view").from(raw_opts.bufnr)
  if not panel then
    return
  end

  panel:show_item(raw_opts.offset)
end

function M.accept(raw_opts)
  raw_opts = raw_opts or {}
  raw_opts.bufnr = raw_opts.bufnr or vim.api.nvim_get_current_buf()

  local panel = require("multito.copilot.panel.view").from(raw_opts.bufnr)
  if not panel then
    return
  end

  panel:accept()
end

function M.get(raw_opts)
  raw_opts = raw_opts or {}
  raw_opts.bufnr = raw_opts.bufnr or vim.api.nvim_get_current_buf()

  local panel = require("multito.copilot.panel.view").from(raw_opts.bufnr)
  if not panel then
    return
  end

  return panel:get()
end

return M
