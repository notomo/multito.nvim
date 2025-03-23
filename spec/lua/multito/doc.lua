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
  },
})

local gen_readme = function()
  local content = ([[
# %s

experiment]]):format(full_plugin_name)

  util.write("README.md", content)
end
gen_readme()
