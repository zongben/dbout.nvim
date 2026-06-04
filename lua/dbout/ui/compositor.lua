local queryer = require("dbout.ui.queryer")

local set_winbar = function(name)
  return "%#Title#Database:[" .. name .. "]%*"
end

--- @type Compositor
local compositor = {
  queryer = {},
}

local attach_buf = function(conn, bufnr)
  local state = {
    conn = conn,
    bufnr = bufnr,
    inspector = nil,
    viewer = nil,
  }

  compositor.queryer[bufnr] = state
  queryer.set_state(state)
  queryer.attach_connection()
end

local M = {}

M.init = function(on_attach)
  queryer.init(on_attach)

  vim.api.nvim_create_autocmd("BufWinEnter", {
    callback = function(args)
      local state = compositor.queryer[args.buf]
      if state and state.conn then
        queryer.set_state(state)
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
