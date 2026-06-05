local queryer = require("dbout.ui.queryer")

local set_winbar = function(name)
  return "%#Title#Database:[" .. name .. "]%*"
end

local compositor = {
  ui = {},
  queryer = {},
  inspector_winnr = nil,
  viewer_winnr = nil,
  api = {},
}

compositor.ui.validate_layout = function()
  local layout = compositor.ui.layout
  if not layout or not layout.inspector or not layout.viewer then
    error("Invalid layout configuration. 'inspector' and 'viewer' must be defined.")
  end

  if layout.inspector <= 0 or layout.viewer <= 0 or layout.inspector > 3 or layout.viewer > 3 then
    error("Invalid layout configuration. 'inspector' and 'viewer' must be between 1 and 3.")
  end

  if layout.inspector == 2 and layout.viewer == 2 then
    error("Invalid layout configuration. 'inspector' and 'viewer' cannot both be 2.")
  end
end

compositor.ui.cal_position = function(panel_name)
  local layout = compositor.ui.layout

  local split
  local win

  if panel_name == "inspector" then
    if layout.inspector == 1 then
      split = "left"
      win = -1
    elseif layout.inspector == 3 then
      split = "right"
      win = -1
    elseif layout.inspector == 2 then
      local is_viewer_winnr_valid = compositor.viewer_winnr and vim.api.nvim_win_is_valid(compositor.viewer_winnr)
      if layout.viewer == 1 then
        if is_viewer_winnr_valid then
          split = "right"
          win = compositor.viewer_winnr
        else
          split = "left"
          win = -1
        end
      elseif layout.viewer == 3 then
        if is_viewer_winnr_valid then
          split = "left"
          win = compositor.viewer_winnr
        else
          split = "right"
          win = -1
        end
      end
    end
  elseif panel_name == "viewer" then
    if layout.viewer == 1 then
      split = "left"
      win = -1
    elseif layout.viewer == 3 then
      split = "right"
      win = -1
    elseif layout.viewer == 2 then
      local is_inspector_winnr_valid = compositor.inspector_winnr
        and vim.api.nvim_win_is_valid(compositor.inspector_winnr)
      if layout.inspector == 1 then
        if is_inspector_winnr_valid then
          split = "right"
          win = compositor.inspector_winnr
        else
          split = "left"
          win = -1
        end
      elseif layout.inspector == 3 then
        if is_inspector_winnr_valid then
          split = "left"
          win = compositor.inspector_winnr
        else
          split = "right"
          win = -1
        end
      end
    end
  end

  return split, win
end

compositor.api = {
  set_or_create_inspector = function(inspector_bufnr)
    if compositor.inspector_winnr and vim.api.nvim_win_is_valid(compositor.inspector_winnr) then
      vim.api.nvim_win_set_buf(compositor.inspector_winnr, inspector_bufnr)
    else
      local split, win = compositor.ui.cal_position("inspector")
      local winnr = vim.api.nvim_open_win(inspector_bufnr, true, {
        split = split,
        win = win,
      })
      compositor.inspector_winnr = winnr
    end

    return compositor.inspector_winnr
  end,
  set_or_create_viewer = function(viewer_bufnr)
    if compositor.viewer_winnr and vim.api.nvim_win_is_valid(compositor.viewer_winnr) then
      vim.api.nvim_win_set_buf(compositor.viewer_winnr, viewer_bufnr)
    else
      local split, win = compositor.ui.cal_position("viewer")
      local winnr = vim.api.nvim_open_win(viewer_bufnr, false, {
        split = split,
        win = win,
      })
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

M.init = function(on_attach, ui)
  compositor.ui.layout = ui.layout
  compositor.ui.validate_layout()

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

M.toggle_viewer = function()
  if compositor.viewer_winnr and vim.api.nvim_win_is_valid(compositor.viewer_winnr) then
    vim.api.nvim_win_close(compositor.viewer_winnr, true)
    compositor.viewer_winnr = nil
  else
    queryer.open_viewer()
  end
end

return M
