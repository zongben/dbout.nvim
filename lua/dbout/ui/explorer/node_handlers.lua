local node_state = require("dbout.enum").node_state
local rpc = require("dbout.rpc")

local toggle_and_render

local create_node = function(parent, children, format)
  local format_children = {}
  for _, child in ipairs(children) do
    table.insert(format_children, format(child))
  end
  parent.children = format_children
end

local M = {}

M.init = function(fn)
  toggle_and_render = fn
end

M.toggle_root = function(root, _)
  if root.is_connected then
    toggle_and_render(root)
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
      create_node(root, db_data[1].rows, function(db)
        return {
          name = db.name,
          node = "db",
          icon = "",
          state = node_state.close,
          is_selected = false,
          children = {},
        }
      end)
      toggle_and_render(root)
    end)
  end)
end

M.toggle_db = function(_, node)
  local db = node
  if db.is_selected then
    toggle_and_render(db)
    return
  end

  db.is_selected = true
  create_node(db, {
    { name = "tables" },
    { name = "views" },
  }, function(folder)
    return {
      name = folder.name,
      node = "folder" .. "_" .. folder.name,
      icon = "",
      state = node_state.close,
      is_selected = false,
      children = {},
      parent = db.name,
    }
  end)
  toggle_and_render(db)
end

M.toggle_folder_tables = function(root, node)
  local folder = node
  if folder.is_selected then
    toggle_and_render(folder)
    return
  end

  rpc.send_jsonrpc("get_table_list", {
    id = root.id,
    dbName = folder.parent,
  }, function(data)
    folder.is_selected = true
    create_node(folder, data[1].rows, function(table)
      return {
        name = table.name,
        node = "table",
        icon = "",
        state = node_state.close,
        is_selected = false,
        children = {},
      }
    end)
    toggle_and_render(folder)
  end)
end

return M
