local tele = require("dbout.tele")
local rpc = require("dbout.rpc")
local viewer = require("dbout.ui.viewer")
local queryer = require("dbout.ui.queryer")

local M = {}

local map = function(bufnr, mode, key, cb)
  if key == "" then
    return
  end
  vim.keymap.set(mode, key, cb, { buffer = bufnr })
end

M.init = function(keymap)
  tele.picker_mappings = function(tele_map)
    local t = keymap.telescope
    tele_map("n", t.new_connection, tele.new_connection)
    tele_map("n", t.delete_connection, tele.delete_connection)
    tele_map("n", t.edit_connection, tele.edit_connection)
  end

  queryer.buffer_mappings = function(buf)
    local q = keymap.queryer
    map(buf, { "n", "i", "v" }, q.query, function()
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
    end)
  end

  viewer.buffer_mappings = function(buf)
    local v = keymap.viewer
    map(buf, { "n" }, v.close, function()
      viewer.close_viewer()
    end)
  end
end

return M
