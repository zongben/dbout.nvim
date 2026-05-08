local queryer = require("dbout.ui.queryer")

--- @type Container
local container = {}

local attach_buf = function(conn, bufnr)
  container[bufnr] = {
    conn = conn,
    bufnr = bufnr,
    inspector = nil,
    viewer = nil,
  }
  queryer.set_state(container[bufnr])
  queryer.attach_connection()
end

local M = {}

M.init = function(on_attach)
  queryer.init(on_attach)
end

M.create_queryer = function(conn)
  local bufnr = vim.api.nvim_create_buf(true, false)
  attach_buf(conn, bufnr)
end

M.attach_queryer = function(conn, bufnr)
  attach_buf(conn, bufnr)
end

return M
