local config = require("dbout.config")
local keymap = require("dbout.keymap")
local cmd = require("dbout.cmd")
local conn = require("dbout.connection")
local container = require("dbout.ui.container")

local M = {}

M.setup = function(opts)
  M.options = vim.tbl_deep_extend("force", config.defaults, opts or {})
  conn.init()
  keymap.init(M.options.keymaps)
  container.init(M.options.on_attach)
  cmd.init()
end

return M
