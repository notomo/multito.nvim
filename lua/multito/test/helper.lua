local helper = require("vusted.helper")
local plugin_name = helper.get_module_root(...)

helper.root = vim.fs.root(0, ".git")
vim.opt.packpath:prepend(vim.fs.joinpath(helper.root, "spec/.shared/packages"))
require("assertlib").register(require("vusted.assert").register)

function helper.before_each() end

function helper.after_each()
  helper.cleanup()
  helper.cleanup_loaded_modules(plugin_name)
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
