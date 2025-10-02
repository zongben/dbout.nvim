local saver = require("dbout.saver")

local connections = {}

local M = {}

local save = function()
  saver.save(connections)
end

M.init = function()
  connections = saver.load()
end

M.is_conn_exists = function(id, name)
  return #vim.tbl_filter(function(c)
    return c.id ~= id and c.name == name
  end, connections) > 0
end

M.get_connections = function()
  return connections
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
