local saver = require("dbout.saver")

local connections = {}

local M = {}

M.init = function()
  connections = saver.load()
end

M.get_connections = function()
  return connections
end

M.add_connection = function(conn)
  table.insert(connections, conn)
  saver.save(connections)
end

M.remove_connection = function(id)
  connections = vim.tbl_filter(function(c)
    return c.id ~= id
  end, connections)
  saver.save(connections)
end

return M
