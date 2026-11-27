local common = require("dbout.source.common")

local source = {}

function source.new(opts)
  local self = setmetatable({}, { __index = source })
  self.common = common.new(opts)
  return self
end

function source:enabled()
  return self.common:enabled(vim.api.nvim_get_current_buf())
end

function source:get_trigger_characters()
  return { "." }
end

function source:get_completions(ctx, callback)
  local function on_complete(items, range)
    for _, item in ipairs(items) do
      item.textEdit = {
        newText = item.label,
        range = vim.deepcopy(range),
      }
      item.insertTextFormat = vim.lsp.protocol.InsertTextFormat.PlainText
    end

    callback({
      items = items,
      is_incomplete_backward = false,
      is_incomplete_forward = false,
    })
  end

  return self.common:get_completions(ctx.bufnr, ctx.bounds.start_col, ctx.cursor, on_complete)
end

function source:resolve(item, callback)
  callback(item)
end

function source:execute(_, _, callback, default_implementation)
  default_implementation()
  callback()
end

return source
