local utils = require("dbout.utils")
local client = require("dbout.client")
local viewer = require("dbout.ui.viewer")
local inspector = require("dbout.ui.inspector")

local set_winbar = function(name)
  return "%#Title#Database:[" .. name .. "]%*"
end

--- @class QueryerState
--- @field conn table
--- @field bufnr integer
--- @field inspector table
--- @field viewer table
local _state = {}

local visual_select = function()
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
  return start_row, end_row
end

local _on_attach = nil

local M = {}

M.buffer_keymappings = nil

M.init = function(on_attach)
  _on_attach = on_attach

  vim.api.nvim_create_autocmd("BufWinEnter", {
    callback = function(args)
      if args.buf ~= _state.bufnr then
        return
      end

      local conn = _state.conn
      if not conn then
        return
      end
      vim.wo.winbar = set_winbar(conn.name)
    end,
  })
end

M.set_state = function(state)
  _state = state
end

M.attach_connection = function()
  local conn = _state.conn
  local bufnr = _state.bufnr

  vim.api.nvim_set_option_value("filetype", "sql", { buf = bufnr })

  M.buffer_keymappings(bufnr)

  if vim.api.nvim_get_current_buf() == bufnr then
    vim.wo.winbar = set_winbar(conn.name)
  end

  utils.switch_win_to_buf(bufnr)
  if _on_attach then
    client.get_connection_info(conn.id, function(jsonstr)
      local info = vim.fn.json_decode(jsonstr)
      _on_attach({
        name = conn.name,
        db_type = conn.db_type,
        host = info.host,
        port = info.port,
        user = info.user,
        password = info.password,
        database = info.database,
        connstr = conn.connstr,
      }, bufnr)
    end)
  end
end

M.open_inspector = function()
  local conn = _state.conn
  local bufnr = _state.bufnr

  inspector.open_inspector(conn, bufnr)
end

M.query = function()
  local conn = _state.conn
  local bufnr = _state.bufnr

  local start_row, end_row = visual_select()

  local sql = table.concat(vim.api.nvim_buf_get_lines(bufnr, start_row, end_row, false), "\n")
  client.query(conn.id, sql, function(jsonstr)
    viewer.open_viewer(jsonstr)
  end)
end

M.format = function()
  local win = vim.api.nvim_get_current_win()
  local bufnr = vim.api.nvim_win_get_buf(win)

  local start_row, end_row = visual_select()

  local sql = table.concat(vim.api.nvim_buf_get_lines(bufnr, start_row, end_row, false), "\n")
  client.format(_state.conn.id, sql, function(jsonstr)
    local str = vim.fn.json_decode(jsonstr)
    local lines = vim.split(str, "\r?\n")
    utils.set_buf_lines(bufnr, lines)
    vim.api.nvim_win_set_buf(win, bufnr)
  end)
end

return M
