local helper = require("multito.test.helper")
local multito = helper.require("multito.copilot")
local assert = require("assertlib").typed(assert)

describe("multito.copilot.panel_completion()", function()
  before_each(helper.before_each)
  after_each(helper.after_each)

  it("opens panel and renders completion text", function()
    local progress = helper.start_progress(function()
      return multito.panel_completion()
    end)
    local observer = progress.observer
    vim.bo.filetype = "multito-test"

    observer.next(helper.progress({
      insertText = "// test1\n// test2",
    }))
    observer.complete()

    assert.exists_pattern([[
// test1
// test2]])
    assert.equal("multito-test", vim.bo.filetype)
  end)

  it("opened buffer can be reloaded", function()
    local progress = helper.start_progress(function()
      return multito.panel_completion()
    end)
    local observer = progress.observer

    observer.next(helper.progress({
      insertText = "// test1\n// test2",
    }))
    observer.complete()

    vim.cmd.edit({ bang = true })

    assert.exists_pattern([[
// test1
// test2]])
  end)
end)

describe("multito.copilot.panel_show_item()", function()
  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can show next item", function()
    local progress = helper.start_progress(function()
      return multito.panel_completion()
    end)
    local observer = progress.observer

    observer.next(helper.progress({
      insertText = "// test1\n// test2",
    }))
    observer.next(helper.progress({
      insertText = "// test3\n// test4",
    }))
    observer.complete()

    multito.panel_show_item({ offset = 1 })

    assert.exists_pattern([[
// test3
// test4]])
  end)

  it("can show previous item", function()
    local progress = helper.start_progress(function()
      return multito.panel_completion({ offset = 1 })
    end)
    local observer = progress.observer

    observer.next(helper.progress({
      insertText = "// test1\n// test2",
    }))
    observer.next(helper.progress({
      insertText = "// test3\n// test4",
    }))
    observer.complete()

    assert.exists_pattern([[
// test3
// test4]])

    multito.panel_show_item({ offset = -1 })

    assert.exists_pattern([[
// test1
// test2]])
  end)
end)

describe("multito.copilot.panel_accept()", function()
  before_each(helper.before_each)
  after_each(helper.after_each)

  it("sets text to source buffer", function()
    local source_bufnr = vim.api.nvim_get_current_buf()

    local progress = helper.start_progress(function()
      return multito.panel_completion()
    end)
    local observer = progress.observer

    observer.next(helper.progress({
      insertText = "// test1\n// test2",
    }))
    observer.complete()

    multito.panel_accept()

    assert.exists_pattern(
      [[
// test1
// test2]],
      source_bufnr
    )
  end)
end)

describe("multito.copilot.panel_get()", function()
  before_each(helper.before_each)
  after_each(helper.after_each)

  it("returns panel info", function()
    local source_bufnr = vim.api.nvim_get_current_buf()

    local progress = helper.start_progress(function()
      return multito.panel_completion()
    end)
    local observer = progress.observer

    local progress_item = helper.progress({
      insertText = "// test1\n// test2",
    })
    observer.next(progress_item)
    observer.complete()

    assert.same({
      current_index = 1,
      done = true,
      items = progress_item.value.items,
      source_bufnr = source_bufnr,
    }, multito.panel_get())
  end)
end)
