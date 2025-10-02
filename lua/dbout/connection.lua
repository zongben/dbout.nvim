local saver = require("dbout.saver")
local utils = require("dbout.utils")
local rpc = require("dbout.rpc")

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

M.start_lsp = function(conn)
  local lsp_name = "sqls" .. "_" .. conn.db_type .. "_" .. conn.name
  vim.lsp.config[lsp_name] = {
    cmd = { "sqls" },
    filetypes = { "sql" },
    settings = {
      sqls = {
        connections = {
          {
            driver = conn.db_type,
            dataSourceName = conn.connstr,
          },
        },
      },
    },
  }
  vim.lsp.enable(lsp_name, true)
end

M.connection = function(conn, cb)
  rpc.send_jsonrpc("create_connection", {
    id = conn.id,
    dbType = conn.db_type,
    connStr = conn.connstr,
  }, function()
    cb()
  end)
end

return M
