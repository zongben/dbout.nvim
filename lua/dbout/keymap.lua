local tele = require("dbout.tele")

local M = {}

M.init = function(keymap)
  tele.picker_mappings = function(map)
    local t = keymap.telescope
    map("n", t.create_connection, tele.create_connection)
  end
end

return M
