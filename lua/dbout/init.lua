local config = require("dbout.config")
local keymap = require("dbout.keymap")
local cmd = require("dbout.cmd")
local conn = require("dbout.connection")
local compositor = require("dbout.ui.compositor")
local viewer = require("dbout.ui.viewer")

local M = {}

M.setup = function(opts)
  M.options = vim.tbl_deep_extend("force", config.defaults, opts or {})
  conn.init()
  keymap.init(M.options.keymaps)
  viewer.init(M.options.viewer)
  compositor.init(M.options.on_attach, M.options.ui)
  cmd.init()
end

return M
