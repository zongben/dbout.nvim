local tele = require("dbout.tele")

local M = {}

M.init = function(keymap)
  tele.picker_mappings = function(map)
    local t = keymap.telescope
    map("n", t.new_connection, tele.new_connection)
    map("n", t.delete_connection, tele.delete_connection)
    map("n", t.edit_connection, tele.edit_connection)
  end
end

return M
