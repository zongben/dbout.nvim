local common = require("dbout.source.common")

local source = {}

function source.new(opts)
  local self = setmetatable({}, { __index = source })
  self.common = common.new(opts)
  return self
end

function source:is_available()
  return self.common:enabled(vim.api.nvim_get_current_buf())
end

function source:get_trigger_characters()
  return { "." }
end

function source:complete(params, callback)
  local bufnr = vim.api.nvim_get_current_buf()
  local cursor = vim.api.nvim_win_get_cursor(0)

  return self.common:get_completions(bufnr, params.offset, cursor, function(items)
    local cmp_items = {}

    for _, item in ipairs(items) do
      table.insert(cmp_items, {
        label = item.label,
        word = item.label,
        kind = item.kind,
      })
    end

    callback({
      items = cmp_items,
      isIncomplete = false,
    })
  end)
end

function source:get_debug_name()
  return "dbout"
end

return source
