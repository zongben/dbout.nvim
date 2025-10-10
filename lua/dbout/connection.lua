local saver = require("dbout.saver")
local utils = require("dbout.utils")
local rpc = require("dbout.rpc")

local connections = {}
local supported_db = { "sqlite3", "postgresql", "mysql", "mssql" }

local M = {}

local save = function()
  saver.save(connections)
end

M.init = function()
  connections = saver.load() or {}
end

M.create_connection = function(connection, cb)
  local fn = function(db_type)
    local name = vim.fn.input("Enter name: ", connection.name or "")
    if not name then
      return
    end

    if M.is_conn_exists(connection.id or "", name) then
      vim.notify(name .. " is used.", vim.log.levels.ERROR)
      return
    end

    local connstr = vim.fn.input("Enter " .. db_type .. " connection string: ", connection.connstr or "")
    if not connstr then
      return
    end

    cb({
      id = connection.id or utils.generate_uuid(),
      name = name,
      db_type = db_type,
      connstr = connstr,
    })
  end

  if connection.id then
    fn(connection.db_type)
    return
  end

  vim.ui.select(M.get_supported_db(), {
    prompt = "Choose a database",
  }, function(db_type)
    if not db_type then
      return
    end
    fn(db_type)
  end)
end

M.is_conn_exists = function(id, name)
  return #vim.tbl_filter(function(c)
    return c.id ~= id and c.name == name
  end, connections) > 0
end

M.get_connections = function()
  return connections
end

M.get_supported_db = function()
  return supported_db
end

M.add_connection = function(conn)
  table.insert(connections, conn)
  save()
end

M.remove_connection = function(id)
  connections = vim.tbl_filter(function(c)
    return c.id ~= id
  end, connections)
  save()
end

M.update_connection = function(conn)
  for _, c in ipairs(connections) do
    if c.id == conn.id then
      c.name = conn.name
      c.db_type = conn.db_type
      c.connstr = conn.connstr
      save()
      return
    end
  end
end

M.open_connection = function(conn, cb)
  rpc.send_jsonrpc("create_connection", {
    id = conn.id,
    dbType = conn.db_type,
    connStr = conn.connstr,
  }, function()
    cb()
  end)
end

return M
