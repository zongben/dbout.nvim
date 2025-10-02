local tele = require("dbout.tele")
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
    map(buf, { "n", "i", "v" }, q.query, queryer.query)
    map(buf, { "n", "i" }, q.table_list, queryer.table_list)
  end

  viewer.buffer_mappings = function(buf)
    local v = keymap.viewer
    map(buf, { "n" }, v.close, function()
      viewer.close_viewer()
    end)
  end
end

return M
