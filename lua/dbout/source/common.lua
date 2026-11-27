local client = require("dbout.client")
local compositor = require("dbout.ui.compositor")

local cache = {}

local M = {}

local function decode_rows(response)
  return vim.json.decode(response).rows or {}
end

local function load_schema(conn_id, bufnr)
  local state = cache[bufnr]
  if state and state.conn_id == conn_id then
    return state
  end

  state = {
    conn_id = conn_id,
    status = "loading",
    tables = {},
    columns = {},
    column_status = {},
    column_waiters = {},
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

  local function loaded()
    pending = pending - 1
    if pending == 0 then
      callback()
    end
  end

  for table_name in pairs(table_names) do
    if state.column_status[table_name] == "loaded" then
      goto continue
    end

    pending = pending + 1
    state.column_waiters[table_name] = state.column_waiters[table_name] or {}
    table.insert(state.column_waiters[table_name], loaded)

    if not state.column_status[table_name] then
      state.column_status[table_name] = "loading"

      client.get_table(conn_id, table_name, function(response)
        state.columns[table_name] = decode_rows(response)
        state.column_status[table_name] = "loaded"

        local waiters = state.column_waiters[table_name]
        state.column_waiters[table_name] = nil
        for _, waiter in ipairs(waiters) do
          waiter()
        end
      end)
    end

    ::continue::
  end

  if pending == 0 then
    callback()
  end
end

local function format_column_documentation(column)
  local lines = {
    ("**Type:** `%s`"):format(column.data_type or "unknown"),
    ("**Nullable:** `%s`"):format(column.is_nullable and "yes" or "no"),
    ("**Primary key:** `%s`"):format(column.is_pk and "yes" or "no"),
    ("**Unique:** `%s`"):format(column.is_unique and "yes" or "no"),
  }

  if column.max_length then
    table.insert(lines, 2, ("**Max length:** `%s`"):format(column.max_length))
  end
  if column.default_value ~= nil and column.default_value ~= vim.NIL then
    table.insert(lines, ("**Default:** `%s`"):format(vim.inspect(column.default_value)))
  end

  return table.concat(lines, "\n")
end

function M.new(opts)
  local self = setmetatable({}, { __index = M })
  self.opts = opts
  return self
end

function M:enabled(bufnr)
  return vim.bo[bufnr].filetype == "sql"
end

function M:get_completions(bufnr, start_col, cursor, callback)
  local queryer = compositor.get_current_queryer()
  if not queryer or queryer.bufnr ~= bufnr then
    callback({})
    return function() end
  end

  local state = load_schema(queryer.conn.id, bufnr)
  if state.status ~= "loaded" then
    callback({})
    return function() end
  end

  local items = {}
  local seen = {}
  local content = table.concat(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), "\n")
  local used_tables = get_used_tables(content, state.tables)

  local function complete()
    local function add_item(label, kind, column)
      if seen[label] then
        return
      end

      seen[label] = true
      local item = {
        label = label,
        kind = kind,
      }

      if column then
        item.detail = column.column_name
        item.documentation = {
          kind = "markdown",
          value = format_column_documentation(column),
        }
      end

      table.insert(items, item)
    end

    for _, table in ipairs(state.tables) do
      add_item(table.table_name, vim.lsp.protocol.CompletionItemKind.Text)
    end

    for table_name in pairs(used_tables) do
      for _, column in ipairs(state.columns[table_name] or {}) do
        add_item(column.column_name, vim.lsp.protocol.CompletionItemKind.Field, column)
      end
    end

    callback(items, {
      start = {
        line = cursor[1] - 1,
        character = start_col - 1,
      },
      ["end"] = {
        line = cursor[1] - 1,
        character = cursor[2],
      },
    })
  end

  load_columns(state, queryer.conn.id, used_tables, complete)

  return function() end
end

return M
