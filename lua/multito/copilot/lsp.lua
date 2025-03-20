local M = {}

function M.start(raw_opts)
  raw_opts = raw_opts or {}

  local version = vim.version()
  local config = vim.tbl_extend("force", {
    cmd = { "copilot-language-server", "--stdio" },
    root_dir = vim.fs.root(0, ".git"),
    init_options = {
      editorInfo = {
        name = "Neovim",
        version = ("%s.%s.%s"):format(version.major, version.minor, version.patch),
      },
      editorPluginInfo = {
        name = "multito.nvim",
        version = "*",
      },
    },
  }, raw_opts.config or {})

  config.name = "copilot"

  local client_id = vim.lsp.start(config)

  return {
    client_id = client_id,
  }
end

function M.get_client(req_ctx)
  local clients = vim.lsp.get_clients({
    bufnr = req_ctx.bufnr,
    method = req_ctx.method,
    name = "copilot",
  })

  local client = clients[1]
  if not client then
    return "no copilot client"
  end

  return client
end

function M.request(req_ctx)
  local promise, resolve, reject = require("multito.vendor.promise").with_resolvers()

  local subscriber = function(observer)
    local method = req_ctx.method
    local bufnr = req_ctx.bufnr

    local client = M.get_client(req_ctx)
    if type(client) == "string" then
      local err = client
      observer:error(err)
      return
    end

    local params = req_ctx.params or {}
    params._ = true

    local ok = false
    local _, request_id = client:request(method, params, function(err, result, ctx)
      if err then
        observer:error(err)
        return
      end

      observer:next({
        result = result,
        ctx = ctx,
      })
      ok = true
      observer:complete()
    end, bufnr)

    local cancel = function()
      if request_id and not ok then
        client:cancel_request(request_id)
      end
      if not ok then
        reject("canceled")
      end
    end

    return cancel
  end

  local observable = require("multito.vendor.misclib.observable").new(subscriber)

  local data
  local subscription = observable:subscribe({
    next = function(x)
      data = x
    end,
    complete = function()
      resolve(data)
    end,
    error = function(err)
      reject(err)
    end,
  })

  return promise, subscription
end

function M.request_progress(progress_ctx)
  local client_id = progress_ctx.client_id
  local partial_result_token = progress_ctx.partial_result_token

  local subscriber = function(observer)
    local group = vim.api.nvim_create_augroup(("multito.copilot.lsp.progress.%s"):format(partial_result_token), {})
    vim.api.nvim_create_autocmd({ "LspProgress" }, {
      group = group,
      pattern = { "*" },
      callback = function(args)
        if args.data.client_id ~= client_id then
          return
        end
        if args.data.params.token ~= partial_result_token then
          return
        end
        observer:next(args.data.params)
      end,
    })

    local promise, subscription = M.request({
      method = progress_ctx.method,
      params = progress_ctx.params,
      bufnr = progress_ctx.bufnr,
    })
    promise
      :next(function()
        observer:complete()
      end)
      :catch(function(err)
        observer:error(err)
      end)

    local cancel = function()
      vim.api.nvim_clear_autocmds({ group = group })
      subscription:unsubscribe()
    end
    return cancel
  end

  return require("multito.vendor.misclib.observable").new(subscriber)
end

function M.workspace_execute_command(execute_ctx)
  local promise, resolve, reject = require("multito.vendor.promise").with_resolvers()

  local client = vim.lsp.get_client_by_id(execute_ctx.client_id)
  if not client then
    reject(("not found lsp client: %s"):format(execute_ctx.client_id))
    return
  end

  client:exec_cmd(execute_ctx.command, { bufnr = execute_ctx.bufnr }, function(err, result, ctx)
    if err then
      reject(err)
      return
    end
    resolve({
      result = result,
      ctx = ctx,
    })
  end)

  return promise
end

return M
