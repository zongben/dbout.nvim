local rpc = require("dbout.rpc")

local send_rpc = function(method, param, cb)
  rpc.send_jsonrpc(method, param, function(jsonstr)
    cb(jsonstr)
  end)
end

local M = {}

M.get_table_list = function(id, cb)
  send_rpc("get_table_list", { id = id }, cb)
end

M.get_view_list = function(id, cb)
  send_rpc("get_view_list", { id = id }, cb)
end

M.get_view = function(id, view_name, cb)
  send_rpc("get_view", { id = id, view_name = view_name }, cb)
end

M.get_store_procedure = function(id, procedure_name, cb)
  send_rpc("get_store_procedure", { id = id, procedure_name = procedure_name }, cb)
end

M.get_store_procedure_list = function(id, cb)
  send_rpc("get_store_procedure_list", { id = id }, cb)
end

M.get_function_list = function(id, cb)
  send_rpc("get_function_list", { id = id }, cb)
end

M.get_trigger_list = function(id, table_name, cb)
  send_rpc("get_trigger_list", { id = id, table_name = table_name }, cb)
end

M.get_function = function(id, function_name, cb)
  send_rpc("get_function", { id = id, function_name = function_name }, cb)
end

M.get_table = function(id, table_name, cb)
  send_rpc("get_table", { id = id, table_name = table_name }, cb)
end

M.get_trigger = function(id, trig_name, cb)
  send_rpc("get_trigger", { id = id, trig_name = trig_name }, cb)
end

M.generate_select_sql = function(id, table_name, cb)
  send_rpc("generate_select_sql", { id = id, table_name = table_name }, cb)
end

M.generate_update_sql = function(id, table_name, cb)
  send_rpc("generate_update_sql", { id = id, table_name = table_name }, cb)
end

M.generate_insert_sql = function(id, table_name, cb)
  send_rpc("generate_insert_sql", { id = id, table_name = table_name }, cb)
end

M.query = function(id, sql, cb)
  send_rpc("query", { id = id, sql = sql }, cb)
end

return M
