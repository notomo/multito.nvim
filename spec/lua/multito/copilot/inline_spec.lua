local helper = require("multito.test.helper")
local multito_inline = helper.require("multito.copilot.inline")
local assert = require("assertlib").typed(assert)

describe("multito.copilot.inline.accept()", function()
  before_each(helper.before_each)
  after_each(helper.after_each)

  it("sets text to buffer", function()
    helper.request({
      request_resolved = {
        ctx = {
          id = "dummyId",
        },
        result = helper.inline_completion({
          insertText = "test1\ntest2\ntest3",
        }),
      },
    }, function()
      return multito_inline.completion()
    end)

    helper.wait(multito_inline.accept())

    assert.exists_pattern([[
test1
test2
test3]])
  end)
end)

describe("multito.copilot.inline.clear()", function()
  before_each(helper.before_each)
  after_each(helper.after_each)

  it("clears extmarks", function()
    helper.request({
      request_resolved = {
        ctx = {
          id = "dummyId",
        },
        result = helper.inline_completion({
          insertText = "test1\ntest2\ntest3",
        }),
      },
    }, function()
      return multito_inline.completion()
    end)

    multito_inline.clear()
    multito_inline.accept()

    assert.no.exists_pattern([[test]])
  end)
end)
