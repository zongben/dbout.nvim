local utils = require("dbout.utils")
local saver = require("dbout.saver")
local rpc = require("dbout.rpc")

local supported_db = { "mssql", "sqlite" }

local connections = {}
local create_connection = function(tbl)
  return {
    id = utils.generate_uuid(),
    name = tbl.name,
    db_type = tbl.db_type,
    connstr = tbl.connstr,
  }
end

local explorer_tree
local node_state = {
  open = "open",
  close = "close",
}

local toggle_state = function(state)
  if state == node_state.open then
    return node_state.close
  else
    return node_state.open
  end
end

local create_root = function(connection)
  table.insert(explorer_tree, {
    id = connection.id,
    name = connection.name,
    db_type = connection.db_type,
    connstr = connection.connstr,
    is_connected = false,
    node = "root",
    state = node_state.close,
    children = {},
  })
end

local create_db_list = function(root_id, db_list)
  for _, root in ipairs(explorer_tree) do
    if root.id == root_id then
      for _, db in ipairs(db_list) do
        table.insert(root.children, {
          name = db.name,
          node = "db",
          is_selected = false,
          state = node_state.close,
          children = {},
        })
      end
      break
    end
  end
end

local create_table_list = function(root_id, db_name, table_list)
  for _, root in ipairs(explorer_tree) do
    if root.id == root_id then
      for _, db in ipairs(root.children) do
        if db.name == db_name then
          for _, t in ipairs(table_list) do
            table.insert(db.children, {
              name = t.table_name,
              node = "table",
            })
          end
          break
        end
      end
      break
    end
  end
end

local M = {}

M.init = function()
  explorer_tree = {}
  connections = saver.load() or {}

  for _, conn in ipairs(connections) do
    create_root(conn)
  end
end

M.render = function(buf)
  local lines = {}
  local line = 1
  for _, root in ipairs(explorer_tree) do
    root.line = line
    root.first_line = line
    table.insert(lines, "󱘖 " .. root.name)
    line = line + 1

    if root.state == node_state.open then
      for _, db in ipairs(root.children) do
        db.line = line
        table.insert(lines, " L  " .. db.name)
        line = line + 1

        if db.state == node_state.open then
          for _, t in ipairs(db.children) do
            t.line = line
            table.insert(lines, "  L " .. t.name)
            line = line + 1
          end
        end
      end
    end

    root.last_line = line - 1
  end

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
end

M.set_keymaps = function(ui, buf)
  local map = function(mode, key, cb)
    vim.keymap.set(mode, key, cb, { buffer = buf })
  end

  map("n", "<CR>", function()
    local win = vim.api.nvim_get_current_win()
    local current_line = vim.api.nvim_win_get_cursor(win)[1]

    local root
    for _, r in ipairs(explorer_tree) do
      if current_line >= r.first_line and current_line <= r.last_line then
        root = r
        break
      end
      return
    end

    if current_line == root.line then
      if root.is_connected then
        root.state = toggle_state(root.state)
        M.render(buf)
        return
      end

      rpc.send_jsonrpc("create_connection", {
        id = root.id,
        dbType = root.db_type,
        connStr = root.connstr,
      }, function(data)
        if data ~= "connected" then
          vim.notify(root.name .. " connection failed", vim.log.levels.WARN)
          return
        end

        rpc.send_jsonrpc("get_db_list", {
          id = root.id,
        }, function(db_data)
          root.is_connected = true
          create_db_list(root.id, db_data[1].rows)
          root.state = toggle_state(root.state)
          M.render(buf)
        end)
      end)
      return
    end

    for _, child in ipairs(root.children) do
      if current_line == child.line then
        if child.is_selected then
          child.state = toggle_state(child.state)
          M.render(buf)
          return
        end

        rpc.send_jsonrpc("get_table_list", {
          id = root.id,
          dbName = child.name,
        }, function(data)
          child.is_selected = true
          create_table_list(root.id, child.name, data[1].rows)
          child.state = toggle_state(child.state)
          M.render(buf)
        end)

        break
      end
    end
  end)

  map("n", "n", function()
    local name = vim.fn.input("Enter name: ")
    if not name then
      return
    end

    vim.ui.select(supported_db, {
      prompt = "choose a database",
    }, function(db_type)
      if not db_type then
        return
      end

      local connstr = vim.fn.input("Enter " .. db_type .. " connection string: ")
      if not connstr then
        return
      end

      local conn = create_connection({
        name = name,
        db_type = db_type,
        connstr = connstr,
      })

      table.insert(connections, conn)
      saver.save(connections)

      create_root(conn)
      M.render(buf)
    end)
  end)

  map("n", "q", function()
    ui.close_db_explorer()
  end)
end

return M
