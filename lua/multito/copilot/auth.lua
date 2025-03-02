local M = {}

function M.sign_in()
  local bufnr = vim.api.nvim_get_current_buf()
  return require("multito.copilot.lsp")
    .request({
      method = "signIn",
      bufnr = bufnr,
    })
    :next(function(data)
      if data.result.status == "AlreadySignedIn" then
        return data
      end

      require("multito.lib.message").info("Authorize in your browser: ", {
        userCode = data.result.userCode,
        verificationUri = data.result.verificationUri,
      })

      vim.fn.setreg("+", data.result.userCode)

      return require("multito.copilot.lsp").workspace_execute_command({
        client_id = data.ctx.client_id,
        bufnr = data.ctx.bufnr,
        command = data.result.command,
      })
    end)
    :next(function(data)
      require("multito.lib.message").info("", data.result)
    end)
    :catch(function(err)
      require("multito.lib.message").warn(err)
    end)
end

function M.sign_out()
  local bufnr = vim.api.nvim_get_current_buf()
  return require("multito.copilot.lsp")
    .request({
      method = "signOut",
      bufnr = bufnr,
    })
    :next(function(data)
      require("multito.lib.message").info("", data.result)
    end)
    :catch(function(err)
      require("multito.lib.message").warn(err)
    end)
end

return M
