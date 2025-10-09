local utils = require("dbout.utils")
local client = require("dbout.client")
local winbar = require("dbout.ui.winbar")

local inspector_bufnr
local conn
local queryer_bufnr

local set_inspector_buf = function()
  local tab = winbar.get_current_tab()

  local fn = function(jsonstr)
    local lines = utils.format_json(jsonstr)
    utils.set_buf_lines(inspector_bufnr, lines)
  end

  if tab == "Tables" then
    client.get_table_list(conn.id, fn)
  elseif tab == "Views" then
    client.get_view_list(conn.id, fn)
  elseif tab == "StoreProcedures" then
    client.get_store_procedure_list(conn.id, fn)
  elseif tab == "Functions" then
    client.get_function_list(conn.id, fn)
  elseif tab == "Columns" then
    client.get_table(conn.id, winbar.get_sub_tab_table(), fn)
  end
end

local inspect_view = function()
  client.get_view_list(conn.id, function(jsonstr)
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
      client.get_view(conn.id, view.view_name, function(v_jsonstr)
        local v = vim.fn.json_decode(v_jsonstr).rows[1].definition
        local lines = vim.split(v, "\r?\n")
        utils.set_buf_lines(queryer_bufnr, lines)
      end)
    end)
  end)
end

local inspect_store_procedure = function()
  client.get_store_procedure_list(conn.id, function(jsonstr)
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
      client.get_store_procedure(conn.id, procedure.procedure_name, function(sp_jsonstr)
        local sp = vim.fn.json_decode(sp_jsonstr).rows[1].definition
        local lines = vim.split(sp, "\r?\n")
        utils.set_buf_lines(queryer_bufnr, lines)
      end)
    end)
  end)
end

local inspect_function = function()
  client.get_function_list(conn.id, function(jsonstr)
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
      client.get_function(conn.id, f.function_name, function(f_jsonstr)
        local sp = vim.fn.json_decode(f_jsonstr).rows[1].definition
        local lines = vim.split(sp, "\r?\n")
        utils.set_buf_lines(queryer_bufnr, lines)
      end)
    end)
  end)
end

local inspect_table = function()
  client.get_table_list(conn.id, function(jsonstr)
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
      local winnr = utils.get_or_create_buf_win(inspector_bufnr)
      vim.api.nvim_win_set_buf(winnr, inspector_bufnr)
      winbar.set_sub_tab_table(t.table_name)
      winbar.tab_switch(2)
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

  local winnr = utils.get_or_create_buf_win(inspector_bufnr)
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
  winbar.tab_switch(1)
  local winnr = utils.get_buf_win(inspector_bufnr)
  winbar.set_winbar(winnr)
  set_inspector_buf()
end

return M
