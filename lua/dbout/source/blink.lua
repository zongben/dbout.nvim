local client = require("dbout.client")
local compositor = require("dbout.ui.compositor")

local m = {
  api = {},
}

m.api.get_tables = function(conn_id, bufnr)
  if m[bufnr] == nil then
    client.get_table_list(conn_id, function(result)
      local tables = vim.json.decode(result).rows
      m[bufnr] = {}
      m[bufnr].tables = tables
    end)
  end

  return m[bufnr].tables
end

--- @module 'blink.cmp'
--- @class blink.cmp.Source
local source = {}

-- `opts` table comes from `sources.providers.your_provider.opts`
-- You may also accept a second argument `config`, to get the full
-- `sources.providers.your_provider` table
function source.new(opts)
  local self = setmetatable({}, { __index = source })
  self.opts = opts
  return self
end

-- (Optional) Enable the source in specific contexts only
function source:enabled()
  return vim.bo.filetype == "sql"
end

-- (Optional) Non-alphanumeric characters that trigger the source
function source:get_trigger_characters()
  return { "." }
end

function source:get_completions(ctx, callback)
  -- vim.notify(vim.inspect(ctx))

  --- @type lsp.CompletionItem[]
  local items = {}

  local queryer = compositor.get_current_queryer()
  if queryer and queryer.bufnr == ctx.bufnr then
    local tables = m.api.get_tables(queryer.conn.id, ctx.bufnr)
    for _, item in ipairs(tables) do
      table.insert(items, {
        label = item.table_name,
        kind = require("blink.cmp.types").CompletionItemKind.Text,
        textEdit = {
          newText = item.table_name,
          range = {
            start = { line = ctx.bounds.line_number, character = ctx.bounds.start_col - 1 },
            ["end"] = { line = ctx.bounds.line_number, character = ctx.cursor[2] },
          },
        },
        insertText = item.table_name,
        insertTextFormat = vim.lsp.protocol.InsertTextFormat.PlainText,
      })
    end
  end

  -- The callback _MUST_ be called at least once. The first time it's called,
  -- blink.cmp will show the results in the completion menu. Subsequent calls
  -- will append the results to the menu to support streaming results.
  --
  -- NOTE: blink.cmp will mutate the items you return, so you must vim.deepcopy them
  -- before returning if you want to re-use them in the future (such as for caching)
  callback({
    items = items,
    -- Whether blink.cmp should request items when deleting characters
    -- from the keyword (e.g. "foo|" -> "fo|")
    -- Note that any non-alphanumeric characters will always request
    -- new items (excluding `-` and `_`)
    is_incomplete_backward = false,
    -- Whether blink.cmp should request items when adding characters
    -- to the keyword (e.g. "fo|" -> "foo|")
    -- Note that any non-alphanumeric characters will always request
    -- new items (excluding `-` and `_`)
    is_incomplete_forward = false,
  })

  -- (Optional) Return a function which cancels the request
  -- If you have long running requests, it's essential you support cancellation
  return function() end
end

-- (Optional) Before accepting the item or showing documentation, blink.cmp will call this function
-- so you may avoid calculating expensive fields (e.g. documentation) for only when they're actually needed
-- Note only some fields may be resolved lazily. You may check the LSP capabilities for a complete list:
-- `textDocument.completion.completionItem.resolveSupport`
-- At the time of writing: 'documentation', 'detail', 'additionalTextEdits', 'command', 'data'
function source:resolve(item, callback)
  -- item = vim.deepcopy(item)

  -- Shown in the documentation window (<C-space> when menu open by default)
  -- item.documentation = {
  --   kind = "markdown",
  --   value = "# Foo\n\nBar",
  -- }

  -- Additional edits to make to the document, such as for auto-imports
  -- item.additionalTextEdits = {
  --   {
  --     newText = "foo",
  --     range = {
  --       start = { line = 0, character = 0 },
  --       ["end"] = { line = 0, character = 0 },
  --     },
  --   },
  -- }

  callback(item)
end

-- (Optional) Called immediately after applying the item's textEdit/insertText
-- Only useful when you want to customize how items are accepted,
-- beyond what's possible with `textEdit` and `additionalTextEdits`
function source:execute(ctx, item, callback, default_implementation)
  -- When you provide an `execute` function, your source must handle the execution
  -- of the item itself, but you may use the default implementation at any time
  default_implementation()

  -- The callback _MUST_ be called once
  callback()
end

return source
