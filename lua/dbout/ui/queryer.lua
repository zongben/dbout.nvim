local client = require("dbout.client")

local _state = nil
local _comp_api = {}
local _on_attach = nil

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

local M = {}

M.buffer_keymappings = nil

M.init = function(on_attach, comp_api)
  _on_attach = on_attach
  _comp_api = comp_api
end

M.set_state = function(state)
  _state = state
end

M.attach_connection = function()
  if not _state then
    return
  end

  local conn = _state.conn
  local bufnr = _state.bufnr

  vim.api.nvim_set_option_value("filetype", "sql", { buf = bufnr })

  M.buffer_keymappings(bufnr)

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
  if not _state then
    return
  end

  if not _state.inspector then
    _state.inspector = require("dbout.ui.inspector").new(_state.conn, _state.bufnr)
  end

  local winnr = _comp_api.set_or_create_inspector(_state.inspector.bufnr)
  _state.inspector.set_winbar(winnr)
end

M.open_viewer = function()
  if not _state then
    return
  end

  if not _state.viewer then
    _state.viewer = require("dbout.ui.viewer").new()
  end

  local winnr = _comp_api.set_or_create_viewer(_state.viewer.bufnr)
  _state.viewer.set_winbar(winnr)
end

M.query = function()
  if not _state then
    return
  end

  local conn = _state.conn
  local bufnr = _state.bufnr

  local start_row, end_row = visual_select()
  local sql = table.concat(vim.api.nvim_buf_get_lines(bufnr, start_row, end_row, false), "\n")

  client.query(conn.id, sql, function(jsonstr)
    if not _state or _state.bufnr ~= bufnr then
      return
    end

    M.open_viewer()
    _state.viewer.set_viewer_buf(jsonstr)
  end)
end

M.format = function()
  if not _state then
    return
  end

  local bufnr = _state.bufnr
  local start_row, end_row = visual_select()
  local sql = table.concat(vim.api.nvim_buf_get_lines(bufnr, start_row, end_row, false), "\n")

  client.format(_state.conn.id, sql, function(jsonstr)
    local str = vim.fn.json_decode(jsonstr)
    local lines = vim.split(str, "\r?\n")
    vim.api.nvim_buf_set_lines(bufnr, start_row, end_row, false, lines)
  end)
end

return M
