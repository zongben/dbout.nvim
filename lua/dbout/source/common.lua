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

local function normalize_identifier(identifier)
  if not identifier then
    return
  end

  local first = identifier:sub(1, 1)
  local last = identifier:sub(-1)
  local pairs = {
    ["'"] = "'",
    ['"'] = '"',
    ["`"] = "`",
    ["["] = "]",
  }

  if pairs[first] == last then
    return identifier:sub(2, -2)
  end

  return identifier
end

local function get_table_references(content, tables)
  local content_lower = content:lower()
  local used = {}
  local qualifiers = {}
  local table_names = {}

  for _, table in ipairs(tables) do
    local name = table.table_name
    local name_lower = name:lower()
    table_names[normalize_identifier(name_lower)] = name
    qualifiers[name_lower] = name
    local pattern = "%f[%w_]" .. vim.pesc(name_lower) .. "%f[^%w_]"

    if content_lower:find(pattern) then
      used[name] = true
    end
  end

  local tokens = {}
  local tokenized_content = content:gsub("([.,()])", " %1 ")
  for token in tokenized_content:gmatch("%S+") do
    table.insert(tokens, token)
  end

  local keywords = {
    as = true,
    cross = true,
    full = true,
    inner = true,
    join = true,
    left = true,
    natural = true,
    on = true,
    outer = true,
    right = true,
    where = true,
  }

  for index, token in ipairs(tokens) do
    local keyword = token:lower()
    if keyword == "from" or keyword == "join" then
      local table_index = index + 1
      local table_name = table_names[normalize_identifier((tokens[table_index] or ""):lower())]

      if not table_name and tokens[table_index + 1] == "." then
        table_index = table_index + 2
        table_name = table_names[normalize_identifier((tokens[table_index] or ""):lower())]
      end

      if table_name then
        local alias_index = table_index + 1
        local alias = tokens[alias_index]
        if alias and normalize_identifier(alias:lower()) == "as" then
          alias_index = alias_index + 1
          alias = tokens[alias_index]
        end

        local normalized_alias = normalize_identifier(alias and alias:lower()) or alias
        if alias and not keywords[normalized_alias] and not table_names[normalized_alias] then
          qualifiers[normalized_alias] = table_name
        end
      end
    end
  end

  return used, qualifiers
end

local function get_completion_qualifier(bufnr, cursor)
  local line = vim.api.nvim_buf_get_lines(bufnr, cursor[1] - 1, cursor[1], false)[1] or ""
  local prefix = line:sub(1, cursor[2])
  return normalize_identifier(prefix:match("([^%s%.]+)%s*%.$"))
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
  local used_tables, qualifiers = get_table_references(content, state.tables)
  local qualifier = get_completion_qualifier(bufnr, cursor)
  local completion_tables = used_tables

  if qualifier then
    local table_name = qualifiers[qualifier:lower()]
    completion_tables = {}
    if table_name then
      completion_tables[table_name] = true
    end
  end

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

    if not qualifier then
      for _, table in ipairs(state.tables) do
        add_item(table.table_name, vim.lsp.protocol.CompletionItemKind.Text)
      end
    end

    for table_name in pairs(completion_tables) do
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

  load_columns(state, queryer.conn.id, completion_tables, complete)

  return function() end
end

return M
