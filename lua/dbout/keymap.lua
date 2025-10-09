local viewer = require("dbout.ui.viewer")
local queryer = require("dbout.ui.queryer")
local inspector = require("dbout.ui.inspector")

local M = {}

local map = function(bufnr, mode, key, cb)
  if key == "" then
    return
  end
  vim.keymap.set(mode, key, cb, { buffer = bufnr, noremap = true, silent = true })
end

M.init = function(keymap, enable_telescope)
  if enable_telescope then
    local tele = require("dbout.tele")
    tele.picker_mappings = function(tele_map)
      local t = keymap.telescope
      tele_map("n", t.new_connection, tele.new_connection)
      tele_map("n", t.delete_connection, tele.delete_connection)
      tele_map("n", t.edit_connection, tele.edit_connection)
      tele_map("n", t.attach_connection, tele.attach_connection)
    end
  end

  queryer.buffer_keymappings = function(buf)
    local q = keymap.queryer
    map(buf, { "i", "v", "n" }, q.query, queryer.query)
    map(buf, { "i", "v", "n" }, q.format, queryer.format)
    map(buf, { "i", "n" }, q.open_inspector, queryer.open_inspector)
  end

  viewer.buffer_keymappings = function(buf)
    local v = keymap.viewer
    map(buf, { "n" }, v.close, viewer.close_viewer)
  end

  inspector.buffer_keymappings = function(buf)
    local i = keymap.inspector
    map(buf, { "n" }, i.close, inspector.close_inspector)
    map(buf, { "n" }, i.next_tab, inspector.next_tab)
    map(buf, { "n" }, i.previous_tab, inspector.previous_tab)
    map(buf, { "n" }, i.inspect, inspector.inspect)
    map(buf, { "n" }, i.back, inspector.back)
  end
end

return M
