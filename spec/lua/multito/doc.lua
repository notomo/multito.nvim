local util = require("genvdoc.util")
local plugin_name = vim.env.PLUGIN_NAME
local full_plugin_name = plugin_name .. ".nvim"

require("genvdoc").generate(full_plugin_name, {
  source = {
    patterns = {
      ("lua/%s/copilot/init.lua"):format(plugin_name),
      ("lua/%s/copilot/inline.lua"):format(plugin_name),
      ("lua/%s/copilot/panel/init.lua"):format(plugin_name),
    },
  },
  chapters = {
    {
      name = function(group)
        return "Lua module: " .. group
      end,
      group = function(node)
        if node.declaration == nil or node.declaration.type ~= "function" then
          return nil
        end
        return node.declaration.module
      end,
    },
    {
      name = "HIGHLIGHT GROUPS",
      body = function(ctx)
        local sections = vim
          .iter(util.extract_documented_table("./lua/multito/highlight_group.lua"))
          :map(function(hl_group)
            return util.help_tagged(ctx, hl_group.key, "hl-" .. hl_group.key)
              .. util.indent(hl_group.document, 2)
              .. "\n"
          end)
          :totable()
        return vim.trim(table.concat(sections, "\n"))
      end,
    },
  },
})

local gen_readme = function()
  local content = ([[
# %s

experiment]]):format(full_plugin_name)

  util.write("README.md", content)
end
gen_readme()
