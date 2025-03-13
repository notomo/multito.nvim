local helper = require("vusted.helper")
local plugin_name = helper.get_module_root(...)

helper.root = vim.fs.root(0, ".git")
vim.opt.packpath:prepend(vim.fs.joinpath(helper.root, "spec/.shared/packages"))
require("assertlib").register(require("vusted.assert").register)

local notify = vim.notify
function helper.before_each()
  vim.g.clipboard = nil
  vim.notify = notify
end

function helper.after_each()
  helper.cleanup()
  helper.cleanup_loaded_modules(plugin_name)
end

function helper.request(result, starter)
  package.loaded["multito.copilot.lsp"] = {
    request = function()
      return require("multito.vendor.promise").resolve(result.request_resolved)
    end,
    workspace_execute_command = function()
      return require("multito.vendor.promise").resolve(result.command_resolved)
    end,
  }
  local finished = false
  starter():finally(function()
    finished = true
  end)
  local ok = vim.wait(1000, function()
    return finished
  end, 10, false)
  if not ok then
    error("wait timeout")
  end
end

function helper.notified()
  local messages = {}
  ---@diagnostic disable-next-line: duplicate-set-field
  vim.notify = function(msg)
    table.insert(messages, msg)
  end
  return messages
end

function helper.clipboard()
  local register = {}
  vim.g.clipboard = {
    name = "test",
    copy = {
      ["+"] = function(lines)
        vim.list_extend(register, lines)
      end,
    },
    paste = {
      ["+"] = function()
        return register
      end,
    },
  }
  return register
end

function helper.start_progress(starter)
  local tbl = {
    observer = nil,
    result = nil,
  }
  package.loaded["multito.copilot.lsp"] = {
    get_client = function()
      return {
        id = "dummyId",
        offset_encoding = "utf-8",
      }
    end,
    request_progress = function()
      return {
        subscribe = function(_, o)
          tbl.observer = o
        end,
      }
    end,
  }
  tbl.result = starter()
  return tbl
end

function helper.progress(item)
  return {
    value = {
      items = {
        vim.tbl_deep_extend("force", {
          command = {
            arguments = { "8888888888888888888888888888888888888888888888888888888888888888" },
            command = "github.copilot.didAcceptPanelCompletionItem",
            title = "Accept completion 1",
          },
          insertText = "",
          range = {
            ["end"] = {
              character = 0,
              line = 0,
            },
            start = {
              character = 0,
              line = 0,
            },
          },
        }, item),
      },
    },
  }
end

return helper
