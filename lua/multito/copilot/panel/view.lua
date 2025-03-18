--- @class MultitoCopilotPanel
--- @field private _current_index integer
--- @field private _items table[]
--- @field private _done boolean
--- @field private _source_bufnr integer
--- @field private _bufnr integer
--- @field private _window_id integer
--- @field private _client_id integer
local M = {}
M.__index = M

local _panels = {}

function M.open(open_ctx)
  local name = ("multito://%s/copilot-panel/%s"):format(open_ctx.source_bufnr, open_ctx.partial_result_token)
  local bufnr = require("multito.vendor.misclib.buffer").find(name) or vim.api.nvim_create_buf(false, true)
  vim.bo[bufnr].filetype = vim.bo[open_ctx.source_bufnr].filetype
  vim.bo[bufnr].bufhidden = "wipe"
  vim.api.nvim_buf_set_name(bufnr, name)

  open_ctx.open(bufnr)

  vim.api.nvim_exec_autocmds("User", {
    pattern = "MultitoCopilotPanelOpened",
    modeline = false,
  })

  local tbl = {
    _bufnr = bufnr,
    _source_bufnr = open_ctx.source_bufnr,
    _current_index = open_ctx.current_index or 0,
    _client_id = open_ctx.client_id,
    _done = open_ctx.done or false,
    _items = open_ctx.items or {},
  }
  local self = setmetatable(tbl, M)

  _panels[bufnr] = self

  vim.api.nvim_create_autocmd({ "BufWipeout" }, {
    group = vim.api.nvim_create_augroup("multito.copilot.panel", {}),
    buffer = bufnr,
    callback = function()
      _panels[bufnr] = nil
    end,
  })
  vim.api.nvim_create_autocmd({ "BufReadCmd" }, {
    buffer = bufnr,
    nested = true,
    callback = function()
      self:_reload()
    end,
  })

  return self
end

function M.add(self, progress)
  vim.list_extend(self._items, progress.value.items)
end

function M.render(self, index)
  index = math.max(1, index)
  index = math.min(index, #self._items)

  if self._current_index == index then
    return
  end
  self._current_index = index

  local item = self._items[index]
  local lines = vim.split(item.insertText, "\n", { plain = true })
  vim.api.nvim_buf_set_lines(self._bufnr, 0, -1, false, lines)

  vim.api.nvim_exec_autocmds("User", {
    pattern = "MultitoCopilotPanelItemShown",
    modeline = false,
  })
end

function M._reload(self)
  local index = self._current_index
  self._current_index = 0
  self:show_item(index)

  vim.bo[self._bufnr].filetype = vim.bo[self._source_bufnr].filetype

  vim.api.nvim_exec_autocmds("User", {
    pattern = "MultitoCopilotPanelOpened",
    modeline = false,
  })
end

function M.show_item(self, offset)
  local index = self._current_index + offset
  self:render(index)
end

function M.done(self)
  self._done = true

  vim.api.nvim_exec_autocmds("User", {
    pattern = "MultitoCopilotPanelDone",
    modeline = false,
  })
end

function M.accept(self)
  local item = self._items[self._current_index]
  local lines = vim.split(item.insertText, "\n", { plain = true })
  vim.api.nvim_buf_set_lines(self._source_bufnr, item.range.start.line, item.range["end"].line, false, lines)

  return require("multito.copilot.lsp").workspace_execute_command({
    client_id = self._client_id,
    bufnr = self._bufnr,
    command = item.command,
  })
end

function M.get(self)
  return {
    done = self._done,
    items = self._items,
    current_index = self._current_index,
    source_bufnr = self._source_bufnr,
    client_id = self._client_id,
  }
end

--- @return MultitoCopilotPanel?
function M.from(bufnr)
  local panel = _panels[bufnr]
  if panel then
    return panel
  end

  if vim.b[bufnr].multito_copilot_panel_debug_state then
    local state = vim.b[bufnr].multito_copilot_panel_debug_state
    local splitted_name = vim.split(vim.api.nvim_buf_get_name(bufnr), "/", { plain = true })
    local partial_result_token = splitted_name[#splitted_name]
    return require("multito.copilot.panel.view").open({
      source_bufnr = state.source_bufnr,
      partial_result_token = partial_result_token,
      open = function() end,
      items = state.items,
      current_index = state.current_index,
      client_id = state.client_id,
      done = state.done,
    })
  end

  return nil
end

return M
