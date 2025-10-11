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

M.init = function(keymaps)
  queryer.buffer_keymappings = function(buf)
    local q = keymaps.queryer
    map(buf, { "i", "v", "n" }, q.query, queryer.query)
    map(buf, { "i", "v", "n" }, q.format, queryer.format)
    map(buf, { "i", "n" }, q.open_inspector, queryer.open_inspector)
  end

  viewer.buffer_keymappings = function(buf)
    local v = keymaps.viewer
    map(buf, { "n" }, v.close, viewer.close_viewer)
  end

  inspector.buffer_keymappings = function(buf)
    local i = keymaps.inspector
    map(buf, { "n" }, i.close, inspector.close_inspector)
    map(buf, { "n" }, i.next_tab, inspector.next_tab)
    map(buf, { "n" }, i.previous_tab, inspector.previous_tab)
    map(buf, { "n" }, i.inspect, inspector.inspect)
    map(buf, { "n" }, i.back, inspector.back)
  end
end

return M
