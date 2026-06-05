local queryer = require("dbout.ui.queryer")

local set_winbar = function(name)
  return "%#Title#Database:[" .. name .. "]%*"
end

--- @type Compositor
local compositor = {
  queryer = {},
  inspector_winnr = nil,
  viewer_winnr = nil,
  api = {},
}

compositor.api = {
  set_or_create_inspector = function(inspector_bufnr)
    if compositor.inspector_winnr and vim.api.nvim_win_is_valid(compositor.inspector_winnr) then
      vim.api.nvim_win_set_buf(compositor.inspector_winnr, inspector_bufnr)
    else
      local winnr = vim.api.nvim_open_win(inspector_bufnr, true, {
        split = "right",
        win = -1,
      })
      compositor.inspector_winnr = winnr
    end

    return compositor.inspector_winnr
  end,
  set_or_create_viewer = function(viewer_bufnr)
    if compositor.viewer_winnr and vim.api.nvim_win_is_valid(compositor.viewer_winnr) then
      vim.api.nvim_win_set_buf(compositor.viewer_winnr, viewer_bufnr)
    else
      local winnr = vim.api.nvim_open_win(viewer_bufnr, true, {
        split = "right",
        win = -1,
      })
      vim.api.nvim_set_option_value("winbar", "%#Title#[Query Result]%*", { win = winnr })
      compositor.viewer_winnr = winnr
    end

    return compositor.viewer_winnr
  end,
}

local attach_buf = function(conn, bufnr)
  local state = {
    conn = conn,
    bufnr = bufnr,
    inspector = nil,
  }

  compositor.queryer[bufnr] = state
  queryer.set_state(state)
  queryer.attach_connection()
end

local M = {}

M.init = function(on_attach)
  queryer.init(on_attach, compositor.api)

  vim.api.nvim_create_autocmd("BufWinEnter", {
    callback = function(args)
      local state = compositor.queryer[args.buf]
      if state and state.conn then
        queryer.set_state(state)

        if compositor.inspector_winnr and vim.api.nvim_win_is_valid(compositor.inspector_winnr) then
          queryer.open_inspector()
        end
      end
    end,
  })

  vim.api.nvim_create_autocmd("BufDelete", {
    callback = function(args)
      if compositor.queryer[args.buf] then
        compositor.queryer[args.buf] = nil
        queryer.set_state(nil)
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

M.toggle_inspector = function()
  if compositor.inspector_winnr and vim.api.nvim_win_is_valid(compositor.inspector_winnr) then
    vim.api.nvim_win_close(compositor.inspector_winnr, true)
    compositor.inspector_winnr = nil
  else
    queryer.open_inspector()
  end
end

return M
