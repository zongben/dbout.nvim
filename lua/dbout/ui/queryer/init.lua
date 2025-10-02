local utils = require("dbout.utils")
local rpc = require("dbout.rpc")
local viewer = require("dbout.ui.viewer")

local current_buffer = {
  connection_id = nil,
}

local M = {}

M.buffer_mappings = nil

M.create_buf = function(connection)
  local bufnr = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_set_option_value("filetype", "sql", { buf = bufnr })
  vim.api.nvim_buf_set_var(bufnr, "connection_id", connection.id)
  vim.api.nvim_buf_set_var(bufnr, "connection_name", connection.name)

  M.buffer_mappings(bufnr)

  vim.api.nvim_create_autocmd("BufEnter", {
    buffer = bufnr,
    callback = function(args)
      local connection_id = vim.api.nvim_buf_get_var(args.buf, "connection_id")
      current_buffer = {
        connection_id = connection_id,
      }

      local connection_name = vim.api.nvim_buf_get_var(args.buf, "connection_name")
      vim.wo.winbar = connection_name
    end,
  })

  utils.switch_win_to_buf(bufnr)
end

M.query = function()
  local win = vim.api.nvim_get_current_win()
  local bufnr = vim.api.nvim_win_get_buf(win)
  local connection_id = vim.api.nvim_buf_get_var(bufnr, "connection_id")

  local start_row, end_row
  if vim.fn.mode():match("[vV\22]") then
    local v_row = vim.fn.getpos("v")[2]
    local c_row = vim.fn.getpos(".")[2]

    if v_row < c_row then
      start_row = v_row
      end_row = c_row
    else
      start_row = c_row
      end_row = v_row
    end
    start_row = start_row - 1
  else
    start_row = 0
    end_row = -1
  end

  local sql = table.concat(vim.api.nvim_buf_get_lines(bufnr, start_row, end_row, false), "\n")
  rpc.send_jsonrpc("query", {
    id = connection_id,
    sql = sql,
  }, function(data)
    viewer.open_viewer(data)
  end)
end

M.table_list = function()
  rpc.send_jsonrpc("get_table_list", {
    id = current_buffer.connection_id,
  }, function(data)
    viewer.open_viewer(data)
  end)
end

return M
