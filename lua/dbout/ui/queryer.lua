local utils = require("dbout.utils")
local rpc = require("dbout.rpc")
local viewer = require("dbout.ui.viewer")

local buffer_connection = {}

local M = {}

M.buffer_keymappings = nil

local start_lsp = function(conn)
  local lsp_name = "sqls" .. "_" .. conn.name
  vim.lsp.config[lsp_name] = {
    cmd = { "sqls" },
    filetypes = { "sql" },
    root_dir = function(bufnr, on_dir)
      if buffer_connection[bufnr] and buffer_connection[bufnr].name == conn.name then
        on_dir()
      end
    end,
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

local buf_detach_lsp = function(bufnr)
  local clients = vim.lsp.get_clients({ bufnr = bufnr })
  for _, client in ipairs(clients) do
    if client.name:match("^sqls") then
      buffer_connection[bufnr] = nil
      vim.lsp.buf_detach_client(bufnr, client.id)
    end
  end
end

M.init = function()
  vim.api.nvim_create_autocmd("BufEnter", {
    callback = function(args)
      local conn = buffer_connection[args.buf]
      if not conn then
        return
      end
      vim.wo.winbar = conn.name
    end,
  })
end

local set_connection_buf = function(connection, bufnr)
  vim.api.nvim_set_option_value("filetype", "sql", { buf = bufnr })
  buffer_connection[bufnr] = connection

  M.buffer_keymappings(bufnr)

  if vim.api.nvim_get_current_buf() == bufnr then
    vim.wo.winbar = connection.name
  end
end

M.create_buf = function(connection)
  local bufnr = vim.api.nvim_create_buf(true, false)
  set_connection_buf(connection, bufnr)
  utils.switch_win_to_buf(bufnr)
  start_lsp(connection)
end

M.attach_buf = function(connection, bufnr)
  buf_detach_lsp(bufnr)
  set_connection_buf(connection, bufnr)
  utils.switch_win_to_buf(bufnr)
  start_lsp(connection)
end

M.query = function()
  local win = vim.api.nvim_get_current_win()
  local bufnr = vim.api.nvim_win_get_buf(win)

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
    id = buffer_connection[bufnr].id,
    sql = sql,
  }, function(data)
    viewer.open_query_result(data)
  end)
end

return M
