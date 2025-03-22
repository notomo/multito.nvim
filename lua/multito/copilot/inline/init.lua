local M = {}

function M.completion(raw_opts)
  raw_opts = raw_opts or {}

  local window_id = vim.api.nvim_get_current_win()
  local bufnr = vim.api.nvim_win_get_buf(window_id)
  local method = "textDocument/inlineCompletion"

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
  local params = {
    textDocument = vim.tbl_extend("force", position_params.textDocument, {
      version = vim.lsp.util.buf_versions[bufnr],
    }),
    position = position_params.position,
    context = {
      triggerKind = vim.lsp.protocol.CompletionTriggerKind.Invoked,
    },
    formattingOptions = {
      tabSize = vim.bo[bufnr].tabstop,
      insertSpaces = vim.bo[bufnr].expandtab,
    },
  }

  return require("multito.copilot.lsp")
    .request({
      method = method,
      bufnr = bufnr,
      params = params,
    })
    :next(function(data)
      local item = data.result.items[1]
      if not item then
        require("multito.lib.message").info("inline completion: no items")
        return
      end

      M.show({
        bufnr = bufnr,
        client_id = data.ctx.client_id,
        item = item,
      })
    end)
    :catch(function(err)
      require("multito.lib.message").warn(err)
    end)
end

local ns = vim.api.nvim_create_namespace("multito.copilot.inline.candidate")

local _candidate = {}

function M.show(show_ctx)
  local bufnr = show_ctx.bufnr

  vim.api.nvim_create_autocmd({ "InsertLeave" }, {
    group = vim.api.nvim_create_augroup("multito.copilot.inline", {}),
    pattern = { "*" },
    callback = function()
      M.clear({ bufnr = show_ctx.bufnr })
    end,
  })

  _candidate[bufnr] = {
    bufnr = bufnr,
    client_id = show_ctx.client_id,
    item = show_ctx.item,
  }

  local range = show_ctx.item.range
  local lines = vim.split(show_ctx.item.insertText, "\n", { plain = true })

  local opts = {
    end_line = range["end"].line,
    end_col = range["end"].character,
    virt_text_pos = "overlay",
    virt_text = { { lines[1], "NormalFloat" } },
  }
  local virt_lines = vim
    .iter(lines)
    :skip(1)
    :map(function(x)
      return { { x, "NormalFloat" } }
    end)
    :totable()
  if #virt_lines > 0 then
    opts.virt_lines = virt_lines
  end
  vim.api.nvim_buf_set_extmark(show_ctx.bufnr, ns, range.start.line, range.start.character, opts)
end

function M.accept(raw_opts)
  raw_opts = raw_opts or {}
  local bufnr = raw_opts.bufnr or vim.api.nvim_get_current_buf()

  local candidate = _candidate[bufnr]
  if not candidate then
    return
  end

  local item = candidate.item
  local lines = vim.split(item.insertText, "\n", { plain = true })
  vim.api.nvim_buf_set_lines(bufnr, item.range.start.line, item.range["end"].line, false, lines)

  M.clear({ bufnr = bufnr })

  return require("multito.copilot.lsp").workspace_execute_command({
    bufnr = bufnr,
    client_id = candidate.client_id,
    command = item.command,
  })
end

function M.clear(raw_opts)
  raw_opts = raw_opts or {}
  local bufnr = raw_opts.bufnr or vim.api.nvim_get_current_buf()

  _candidate[bufnr] = nil
  vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
end

return M
