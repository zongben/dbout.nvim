local queryer = require("dbout.ui.queryer")

local set_winbar = function(name)
  return "%#Title#Database:[" .. name .. "]%*"
end

--- @type Compositor
local compositor = {}

local attach_buf = function(conn, bufnr)
  compositor[bufnr] = {
    conn = conn,
    bufnr = bufnr,
    inspector = nil,
    viewer = nil,
  }
  queryer.set_state(compositor[bufnr])
  queryer.attach_connection()
end

local M = {}

M.init = function(on_attach)
  queryer.init(on_attach)

  vim.api.nvim_create_autocmd("BufWinEnter", {
    callback = function(args)
      local _state = compositor[args.buf]
      if _state and _state.conn then
        queryer.set_state(_state)
      end
    end,
  })
end

M.create_queryer = function(conn)
  local bufnr = vim.api.nvim_create_buf(true, false)
  attach_buf(conn, bufnr)

  local winnr = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(winnr, bufnr)
  vim.api.nvim_set_current_win(winnr)
  vim.wo.winbar = set_winbar(conn.name)
end

M.attach_queryer = function(conn, bufnr)
  attach_buf(conn, bufnr)
end

return M
