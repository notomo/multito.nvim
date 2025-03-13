local helper = require("multito.test.helper")
local multito = helper.require("multito.copilot")
local assert = require("assertlib").typed(assert)

describe("multito.copilot.sign_in()", function()
  before_each(helper.before_each)
  after_each(helper.after_each)

  it("does nothing if already signed in", function()
    local messages = helper.notified()

    helper.request({
      request_resolved = {
        result = {
          status = "AlreadySignedIn",
        },
      },
    }, function()
      return multito.sign_in()
    end)

    assert.match("AlreadySignedIn", messages[#messages])
  end)

  it("copies user code to verify", function()
    local register = helper.clipboard()
    local messages = helper.notified()

    helper.request({
      request_resolved = {
        result = {
          userCode = "ABCD-EFGH",
          command = {
            command = "github.copilot.finishDeviceFlow",
            arguments = {},
            title = "Sign in",
          },
        },
        ctx = {
          client_id = "duumy",
          bufnr = 8888,
        },
      },
      command_resolved = {
        result = {
          status = "OK",
          user = "name",
        },
      },
    }, function()
      return multito.sign_in()
    end)

    assert.match("OK", messages[#messages])
    assert.equal("ABCD-EFGH", register[#register])
  end)
end)

describe("multito.copilot.sign_out()", function()
  before_each(helper.before_each)
  after_each(helper.after_each)

  it("notifies status", function()
    local messages = helper.notified()

    helper.request({
      request_resolved = {
        result = {
          status = "NotSignedIn",
        },
      },
    }, function()
      return multito.sign_out()
    end)

    assert.match("NotSignedIn", messages[#messages])
  end)
end)
