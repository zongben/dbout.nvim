local saver = require("dbout.saver")
local utils = require("dbout.utils")

local connections = {}
local supported_db = { "mssql", "sqlite" }

local M = {}

local save = function()
  saver.save(connections)
end

M.init = function()
  connections = saver.load()
end

M.create_connection = function(name, db_type, connstr)
  return {
    id = utils.generate_uuid(),
    name = name,
    db_type = db_type,
    connstr = connstr,
  }
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
      c = conn
      return
    end
  end
  save()
end

return M
