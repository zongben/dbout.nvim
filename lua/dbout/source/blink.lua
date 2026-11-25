local client = require("dbout.client")
local compositor = require("dbout.ui.compositor")
local cmp_types = require("blink.cmp.types")

local cache = {}

--- @module 'blink.cmp'
--- @class blink.cmp.Source
local source = {}

local function decode_rows(response)
  return vim.json.decode(response).rows or {}
end

local function load_schema(conn_id, bufnr)
  if cache[bufnr] then
    return cache[bufnr]
  end

  local state = {
    status = "loading",
    tables = {},
    columns = {},
    column_status = {},
  }
  cache[bufnr] = state

  client.get_table_list(conn_id, function(response)
    state.tables = decode_rows(response)
    state.status = "loaded"
  end)

  return state
end

local function get_used_tables(content, tables)
  local content_lower = content:lower()
  local used = {}

  for _, table in ipairs(tables) do
    local name = table.table_name
    local name_lower = name:lower()
    local pattern = "%f[%w_]" .. vim.pesc(name_lower) .. "%f[^%w_]"

    if content_lower:find(pattern) then
      used[name] = true
    end
  end

  return used
end

local function load_columns(state, conn_id, table_names, callback)
  local pending = 0

  for table_name in pairs(table_names) do
    if not state.column_status[table_name] then
      state.column_status[table_name] = "loading"
      pending = pending + 1

      client.get_table(conn_id, table_name, function(response)
        state.columns[table_name] = decode_rows(response)
        state.column_status[table_name] = "loaded"
        pending = pending - 1

        if pending == 0 then
          callback()
        end
      end)
    end
  end

  if pending == 0 then
    callback()
  end
end

local function completion_range(ctx)
  return {
    start = {
      line = ctx.bounds.line_number - 1,
      character = ctx.bounds.start_col - 1,
    },
    ["end"] = {
      line = ctx.cursor[1] - 1,
      character = ctx.cursor[2],
    },
  }
end

function source.new(opts)
  local self = setmetatable({}, { __index = source })
  self.opts = opts

  local queryer = compositor.get_current_queryer()
  if queryer then
    load_schema(queryer.conn.id, queryer.bufnr)
  end

  return self
end

function source:enabled()
  return vim.bo.filetype == "sql"
end

function source:get_trigger_characters()
  return { "." }
end

function source:get_completions(ctx, callback)
  local queryer = compositor.get_current_queryer()
  if not queryer or queryer.bufnr ~= ctx.bufnr then
    callback({ items = {}, is_incomplete_backward = false, is_incomplete_forward = false })
    return function() end
  end

  local state = cache[ctx.bufnr] or load_schema(queryer.conn.id, ctx.bufnr)
  if state.status ~= "loaded" then
    callback({ items = {}, is_incomplete_backward = false, is_incomplete_forward = false })
    return function() end
  end

  local items = {}
  local seen = {}
  local content = table.concat(vim.api.nvim_buf_get_lines(ctx.bufnr, 0, -1, false), "\n")
  local used_tables = get_used_tables(content, state.tables)
  local range = completion_range(ctx)

  local function complete()
    local function add_item(label, kind)
      if seen[label] then
        return
      end

      seen[label] = true

      table.insert(items, {
        label = label,
        kind = kind,
        textEdit = {
          newText = label,
          range = vim.deepcopy(range),
        },
        insertTextFormat = vim.lsp.protocol.InsertTextFormat.PlainText,
      })
    end

    for _, table in ipairs(state.tables) do
      add_item(table.table_name, cmp_types.CompletionItemKind.Text)
    end

    for table_name in pairs(used_tables) do
      for _, column in ipairs(state.columns[table_name] or {}) do
        add_item(column.column_name, cmp_types.CompletionItemKind.Field)
      end
    end

    callback({
      items = items,
      is_incomplete_backward = false,
      is_incomplete_forward = false,
    })
  end

  load_columns(state, queryer.conn.id, used_tables, complete)

  return function() end
end

function source:resolve(item, callback)
  callback(item)
end

function source:execute(ctx, item, callback, default_implementation)
  default_implementation()
  callback()
end

return source
