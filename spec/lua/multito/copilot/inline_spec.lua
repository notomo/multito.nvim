local helper = require("multito.test.helper")
local multito_inline = helper.require("multito.copilot.inline")
local assert = require("assertlib").typed(assert)

describe("multito.copilot.inline.accept()", function()
  before_each(helper.before_each)
  after_each(helper.after_each)

  it("sets text to buffer", function()
    helper.set_lines([[before]])

    helper.request({
      request_resolved = {
        ctx = {
          id = "dummyId",
        },
        result = helper.inline_completion({
          insertText = "before test1\ntest2\ntest3",
          range = {
            start = {
              line = 0,
              character = 0,
            },
            ["end"] = {
              line = 0,
              character = 6,
            },
          },
        }),
      },
    }, function()
      return multito_inline.completion()
    end)

    helper.wait(multito_inline.accept())

    assert.exists_pattern([[
before test1
test2
test3]])

    assert.cursor_row(3)
    assert.cursor_column(5)
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

describe("multito.copilot.inline.get()", function()
  before_each(helper.before_each)
  after_each(helper.after_each)

  it("return items", function()
    local value = helper.inline_completion({
      insertText = "test",
    })

    helper.request({
      request_resolved = {
        ctx = {
          id = "dummyId",
        },
        result = value,
      },
    }, function()
      return multito_inline.completion()
    end)

    local got = multito_inline.get()
    assert.same({
      items = { value.items[1] },
    }, got)
  end)

  it("return nil if no completion", function()
    local got = multito_inline.get()
    assert.is_nil(got)
  end)
end)
