local explorer = require("dbout.ui.explorer")
local main = require("dbout.ui.main")

local inited = false

local M = {}

M.is_inited = function()
  return inited
end

M.init = function()
  main.init()
  explorer.init()

  inited = true
end

M.open_dbout = function()
  main.open_dbout()
end

M.open_db_explorer = function()
  explorer.open_db_explorer()
end

M.close_db_explorer = function()
  explorer.close_db_explorer()
end

return M
