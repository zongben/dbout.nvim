local utils = require("dbout.utils")
local rpc = require("dbout.rpc")

local inspector_bufnr
local conn_id

local current_tab_index = 1
local tabs = {
  "Tables",
  "Views",
  "StoreProcedures",
  "Functions",
}

local get_table_list = function()
  rpc.send_jsonrpc("get_table_list", {
    id = conn_id,
  }, function(jsonstr)
    local lines = utils.format_json(jsonstr)
    utils.set_buf_lines(inspector_bufnr, lines)
  end)
end

local get_view_list = function()
  rpc.send_jsonrpc("get_view_list", {
    id = conn_id,
  }, function(jsonstr)
    local lines = utils.format_json(jsonstr)
    utils.set_buf_lines(inspector_bufnr, lines)
  end)
end

local get_store_procedure_list = function()
  rpc.send_jsonrpc("get_store_procedure_list", {
    id = conn_id,
  }, function(jsonstr)
    local lines = utils.format_json(jsonstr)
    utils.set_buf_lines(inspector_bufnr, lines)
  end)
end

local get_function_list = function()
  rpc.send_jsonrpc("get_function_list", {
    id = conn_id,
  }, function(jsonstr)
    local lines = utils.format_json(jsonstr)
    utils.set_buf_lines(inspector_bufnr, lines)
  end)
end

local set_inspector_buf = function()
  local tab = tabs[current_tab_index]

  if tab == "Tables" then
    get_table_list()
  elseif tab == "Views" then
    get_view_list()
  elseif tab == "StoreProcedures" then
    get_store_procedure_list()
  elseif tab == "Functions" then
    get_function_list()
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
  set_inspector_buf()
end

local M = {}

M.buffer_keymappings = nil

M.open_inspector = function(connection_id)
  conn_id = connection_id

  if inspector_bufnr == nil then
    inspector_bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_option_value("filetype", "json", { buf = inspector_bufnr })
    M.buffer_keymappings(inspector_bufnr)
  end

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

return M
