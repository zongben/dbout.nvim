local utils = require("dbout.utils")
local rpc = require("dbout.rpc")

local inspector_bufnr
local conn_id
local queryer_bufnr

local current_tab_index = 1
local tabs = {
  "Tables",
  "Views",
  "StoreProcedures",
  "Functions",
}

local send_rpc = function(method, param, cb)
  rpc.send_jsonrpc(method, param, function(jsonstr)
    cb(jsonstr)
  end)
end

local get_table_list = function(cb)
  send_rpc("get_table_list", { id = conn_id }, cb)
end

local get_view_list = function(cb)
  send_rpc("get_view_list", { id = conn_id }, cb)
end

local get_view = function(view_name, cb)
  send_rpc("get_view", { id = conn_id, view_name = view_name }, cb)
end

local get_store_procedure_list = function(cb)
  send_rpc("get_store_procedure_list", { id = conn_id }, cb)
end

local get_function_list = function(cb)
  send_rpc("get_function_list", { id = conn_id }, cb)
end

local set_inspector_buf = function()
  local tab = tabs[current_tab_index]

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
  end
end

local set_winbar = function(winnr)
  local bar = {}
  for index, tab in ipairs(tabs) do
    if index == current_tab_index then
      table.insert(bar, "%#Title#[" .. tab .. "]%*")
    else
      table.insert(bar, tab)
    end
  end
  vim.api.nvim_set_option_value("winbar", table.concat(bar, "|"), { win = winnr })
  vim.api.nvim_win_set_cursor(winnr, { 1, 0 })
  set_inspector_buf()
end

local inspect_views_detail = function()
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

local M = {}

M.buffer_keymappings = nil

M.open_inspector = function(connection_id, bufnr)
  conn_id = connection_id
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
  set_winbar(winnr)
end

M.close_inspector = function()
  utils.close_buf_win(inspector_bufnr)
end

M.next_tab = function()
  current_tab_index = current_tab_index + 1
  if current_tab_index > #tabs then
    current_tab_index = 1
  end

  local winnr = utils.get_buf_win(inspector_bufnr)
  set_winbar(winnr)
end

M.previous_tab = function()
  current_tab_index = current_tab_index - 1
  if current_tab_index < 1 then
    current_tab_index = #tabs
  end

  local winnr = utils.get_buf_win(inspector_bufnr)
  set_winbar(winnr)
end

M.inspect_detail = function()
  local tab = tabs[current_tab_index]

  if tab == "Tables" then
  elseif tab == "Views" then
    inspect_views_detail()
  end
end

return M
