local config = require("dbout.config")
local keymap = require("dbout.keymap")
local cmd = require("dbout.cmd")
local conn = require("dbout.connection")
local queryer = require("dbout.ui.queryer")

local M = {}

M.setup = function(opts)
  M.options = vim.tbl_deep_extend("force", config.defaults, opts or {})
  conn.init()
  keymap.init(M.options.keymap, M.options.enable_telescope)
  queryer.init()
  cmd.init(M.options.enable_telescope)
end

return M
