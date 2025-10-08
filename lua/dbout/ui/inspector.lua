local utils = require("dbout.utils")
local rpc = require("dbout.rpc")
local winbar = require("dbout.ui.winbar")

local inspector_bufnr
local conn
local queryer_bufnr

local send_rpc = function(method, param, cb)
  rpc.send_jsonrpc(method, param, function(jsonstr)
    cb(jsonstr)
  end)
end

local get_table_list = function(cb)
  send_rpc("get_table_list", { id = conn.id }, cb)
end

local get_view_list = function(cb)
  send_rpc("get_view_list", { id = conn.id }, cb)
end

local get_view = function(view_name, cb)
  send_rpc("get_view", { id = conn.id, view_name = view_name }, cb)
end

local get_store_procedure = function(procedure_name, cb)
  send_rpc("get_store_procedure", { id = conn.id, procedure_name = procedure_name }, cb)
end

local get_store_procedure_list = function(cb)
  send_rpc("get_store_procedure_list", { id = conn.id }, cb)
end

local get_function_list = function(cb)
  send_rpc("get_function_list", { id = conn.id }, cb)
end

local get_function = function(function_name, cb)
  send_rpc("get_function", { id = conn.id, function_name = function_name }, cb)
end

local get_table = function(table_name, cb)
  send_rpc("get_table", { id = conn.id, table_name = table_name }, cb)
end

local set_inspector_buf = function()
  local tab, extra = winbar.get_current_tab()

  local fn = function(jsonstr)
    local lines = utils.format_json(jsonstr)
    utils.set_buf_lines(inspector_bufnr, lines)
  end

  if tab == "Tables" then
    get_table_list(fn)
  elseif tab == "Views" then
    get_view_list(fn)
  elseif tab == "StoreProcedures" then
    get_store_procedure_list(fn)
  elseif tab == "Functions" then
    get_function_list(fn)
  elseif tab == "TableColumns" then
    get_table(extra, fn)
  end
end

local inspect_view = function()
  get_view_list(function(jsonstr)
    local data = vim.fn.json_decode(jsonstr)
    vim.ui.select(data.rows, {
      prompt = "Inspect a view",
      format_item = function(item)
        return item.view_name
      end,
    }, function(view)
      if not view then
        return
      end
      get_view(view.view_name, function(v_jsonstr)
        local v = vim.fn.json_decode(v_jsonstr).rows[1].definition
        local lines = vim.split(v, "\r?\n")
        utils.set_buf_lines(queryer_bufnr, lines)
      end)
    end)
  end)
end

local inspect_store_procedure = function()
  get_store_procedure_list(function(jsonstr)
    local data = vim.fn.json_decode(jsonstr)
    vim.ui.select(data.rows, {
      prompt = "Inspect a store procedure",
      format_item = function(item)
        return item.procedure_name
      end,
    }, function(procedure)
      if not procedure then
        return
      end
      get_store_procedure(procedure.procedure_name, function(sp_jsonstr)
        local sp = vim.fn.json_decode(sp_jsonstr).rows[1].definition
        local lines = vim.split(sp, "\r?\n")
        utils.set_buf_lines(queryer_bufnr, lines)
      end)
    end)
  end)
end

local inspect_function = function()
  get_function_list(function(jsonstr)
    local data = vim.fn.json_decode(jsonstr)
    vim.ui.select(data.rows, {
      prompt = "Inspect a function",
      format_item = function(item)
        return item.function_name
      end,
    }, function(f)
      if not f then
        return
      end
      get_function(f.function_name, function(f_jsonstr)
        local sp = vim.fn.json_decode(f_jsonstr).rows[1].definition
        local lines = vim.split(sp, "\r?\n")
        utils.set_buf_lines(queryer_bufnr, lines)
      end)
    end)
  end)
end

local inspect_table = function()
  get_table_list(function(jsonstr)
    local data = vim.fn.json_decode(jsonstr)
    vim.ui.select(data.rows, {
      prompt = "Inspect a table",
      format_item = function(item)
        return item.table_name
      end,
    }, function(t)
      if not t then
        return
      end
      local winnr = utils.get_buf_win(inspector_bufnr)
      if not winnr then
        winnr = utils.create_right_win()
      end
      vim.api.nvim_win_set_buf(winnr, inspector_bufnr)
      winbar.create_sub_tab(t.table_name)
      winbar.set_winbar(winnr)
      set_inspector_buf()
    end)
  end)
end

local M = {}

M.buffer_keymappings = nil

M.open_inspector = function(connection, bufnr)
  conn = connection
  queryer_bufnr = bufnr

  if inspector_bufnr == nil then
    inspector_bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_option_value("filetype", "json", { buf = inspector_bufnr })
  end

  M.buffer_keymappings(inspector_bufnr)

  local winnr = utils.get_buf_win(inspector_bufnr)
  if not winnr then
    winnr = utils.create_right_win()
  end
  vim.api.nvim_win_set_buf(winnr, inspector_bufnr)
  winbar.set_winbar(winnr)
  set_inspector_buf()
end

M.reset = function()
  utils.close_buf_win(inspector_bufnr)
  winbar.reset()
end

M.close_inspector = function()
  utils.close_buf_win(inspector_bufnr)
end

M.next_tab = function()
  winbar.next_tab()
  local winnr = utils.get_buf_win(inspector_bufnr)
  winbar.set_winbar(winnr)
  set_inspector_buf()
end

M.previous_tab = function()
  winbar.previous_tab()
  local winnr = utils.get_buf_win(inspector_bufnr)
  winbar.set_winbar(winnr)
  set_inspector_buf()
end

M.inspect = function()
  local tab = winbar.get_current_tab()

  if tab == "Tables" then
    inspect_table()
  elseif tab == "Views" then
    inspect_view()
  elseif tab == "StoreProcedures" then
    if conn.db_type == "sqlite3" then
      return
    end
    inspect_store_procedure()
  elseif tab == "Functions" then
    if conn.db_type == "sqlite3" then
      return
    end
    inspect_function()
  end
end

M.back = function()
  winbar.back()
  local winnr = utils.get_buf_win(inspector_bufnr)
  winbar.set_winbar(winnr)
  set_inspector_buf()
end

return M
