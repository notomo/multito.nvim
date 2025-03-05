local M = {}

function M.completion()
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

  local panel = M._open({
    source_bufnr = bufnr,
    client = client,
  })

  observable:subscribe({
    next = function(progress)
      panel.add(progress)
      panel.render(1)
    end,
    complete = function()
      panel.done()
    end,
    error = function(err)
      require("multito.lib.message").warn(err)
    end,
  })
end

local ns = vim.api.nvim_create_namespace("multito.copilot.panel")
local _panels = {}

function M._open(open_ctx)
  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.bo[bufnr].filetype = vim.bo[open_ctx.source_bufnr].filetype
  vim.bo[bufnr].bufhidden = "wipe"

  local current_index = 0
  local done = false
  local items = {}
  local info_id

  vim.cmd.vsplit()
  vim.cmd.buffer(bufnr)
  local window_id = vim.api.nvim_get_current_win()
  vim.api.nvim_create_autocmd({ "BufWipeout" }, {
    group = vim.api.nvim_create_augroup("multito.copilot.panel", {}),
    buffer = bufnr,
    callback = function()
      _panels[bufnr] = nil
    end,
  })

  local render_info = function()
    info_id = vim.api.nvim_buf_set_extmark(bufnr, ns, 0, 0, {
      id = info_id,
      virt_lines = {
        {
          { ("[%s / %s] %s"):format(current_index, #items, done and "" or "..."), "Comment" },
        },
      },
      virt_lines_above = true,
      right_gravity = false,
    })
    vim.api.nvim_win_call(window_id, function()
      local cursor = vim.api.nvim_win_get_cursor(window_id)
      vim.cmd.normal({ args = { vim.keycode("<C-b>") }, bang = true }) -- workaround to show virt lines
      vim.api.nvim_win_set_cursor(window_id, cursor)
    end)

    vim.wo[window_id].winbar = ("[%s / %s] %s"):format(current_index, #items, done and "" or "...")
  end
  render_info()

  vim.api.nvim_exec_autocmds("User", {
    pattern = "MultitoCopilotPanelOpened",
    modeline = false,
  })

  local render_item = function(index)
    index = math.max(1, index)
    index = math.min(index, #items)

    if current_index == index then
      return
    end
    current_index = index

    local item = items[index]
    local lines = vim.split(item.insertText, "\n", { plain = true })
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
    vim.api.nvim_win_set_cursor(window_id, { 1, 0 })

    render_info()
  end

  local self = {
    add = function(progress)
      vim.list_extend(items, progress.value.items)
    end,
    render = function(index)
      render_item(index)
    end,
    done = function()
      done = true
      render_info()
    end,
    next = function(offset)
      render_item(current_index + offset)
    end,
    accept = function()
      local item = items[current_index]
      local lines = vim.split(item.insertText, "\n", { plain = true })
      vim.api.nvim_buf_set_lines(open_ctx.source_bufnr, item.range.start.line, item.range["end"].line, false, lines)
    end,
  }
  _panels[bufnr] = self
  return self
end

function M.show_item(raw_opts)
  raw_opts = raw_opts or {}
  raw_opts.offset = raw_opts.offset or 1

  local bufnr = vim.api.nvim_get_current_buf()
  local panel = _panels[bufnr]
  if not panel then
    return
  end

  panel.next(raw_opts.offset)
end

function M.accept()
  local bufnr = vim.api.nvim_get_current_buf()
  local panel = _panels[bufnr]
  if not panel then
    return
  end

  panel.accept()
end

return M
