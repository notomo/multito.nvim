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

  local panel = M._open({
    source_bufnr = bufnr,
    client = client,
    partial_result_token = partial_result_token,
  })

  observable:subscribe({
    next = function(progress)
      panel.add(progress)
      panel.render(1 + raw_opts.offset)
    end,
    complete = function()
      panel.done()
    end,
    error = function(err)
      require("multito.lib.message").warn(err)
    end,
  })
end

local _panels = {}

function M._open(open_ctx)
  local name = ("multito://%s/copilot-panel/%s"):format(open_ctx.source_bufnr, open_ctx.partial_result_token)
  local bufnr = require("multito.vendor.misclib.buffer").find(name) or vim.api.nvim_create_buf(false, true)
  vim.bo[bufnr].filetype = vim.bo[open_ctx.source_bufnr].filetype
  vim.bo[bufnr].bufhidden = "wipe"
  vim.api.nvim_buf_set_name(bufnr, name)

  local current_index = 0
  local done = false
  local items = {}

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

    vim.api.nvim_exec_autocmds("User", {
      pattern = "MultitoCopilotPanelItemShown",
      modeline = false,
    })
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
      M._save({
        items = items,
        partial_result_token = open_ctx.partial_result_token,
      })

      vim.api.nvim_exec_autocmds("User", {
        pattern = "MultitoCopilotPanelDone",
        modeline = false,
      })
    end,
    next = function(offset)
      render_item(current_index + offset)
    end,
    accept = function()
      local item = items[current_index]
      local lines = vim.split(item.insertText, "\n", { plain = true })
      vim.api.nvim_buf_set_lines(open_ctx.source_bufnr, item.range.start.line, item.range["end"].line, false, lines)
    end,
    get = function()
      return {
        done = done,
        items = items,
        current_index = current_index,
      }
    end,
  }
  _panels[bufnr] = self
  return self
end

function M._save(save_ctx)
  local path =
    vim.fs.joinpath(vim.fn.stdpath("data"), "multito/copilot-panel", ("%s.json"):format(save_ctx.partial_result_token))
  vim.fn.mkdir(vim.fs.dirname(path), "p")
  local f = io.open(path, "w")
  if not f then
    error("can't open file: " .. path)
  end
  f:write(vim.json.encode(save_ctx.items))
  f:close()
end

function M._restore(restore_ctx)
  local path = vim.fs.joinpath(
    vim.fn.stdpath("data"),
    "multito/copilot-panel",
    ("%s.json"):format(restore_ctx.partial_result_token)
  )
  local f = io.open(path, "r")
  if not f then
    return {}
  end
  local content = f:read("*a")
  return vim.json.decode(content)
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

function M.get(raw_opts)
  raw_opts = raw_opts or {}
  raw_opts.bufnr = raw_opts.bufnr or vim.api.nvim_get_current_buf()
  local panel = _panels[raw_opts.bufnr]
  if not panel then
    return
  end
  return panel.get()
end

return M
