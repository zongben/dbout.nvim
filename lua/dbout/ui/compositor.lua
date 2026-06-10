local queryer = require("dbout.ui.queryer")
local utils = require("dbout.utils")

local set_winbar = function(name)
  return "%#Title#Database:[" .. name .. "]%*"
end

local compositor = {
  ui = {
    layout = {},
  },
  queryer = {},
  inspector = { winnr = nil },
  viewer = { winnr = nil },
  api = {},
}

compositor.ui.validate_layout = function()
  local layout = compositor.ui.layout
  if not layout or not layout.inspector or not layout.viewer then
    error("Invalid layout configuration. 'inspector' and 'viewer' must be defined.")
  end

  local is_valid_range = function(val)
    return val >= 1 and val <= 3
  end
  if not (is_valid_range(layout.inspector) and is_valid_range(layout.viewer)) then
    error("Invalid layout configuration. 'inspector' and 'viewer' must be between 1 and 3.")
  end

  if layout.inspector == 2 and layout.viewer == 2 then
    error("Invalid layout configuration. 'inspector' and 'viewer' cannot both be 2.")
  end
end

compositor.ui.suspend_scratch_wins = function()
  for _, panel in ipairs({ compositor.inspector, compositor.viewer }) do
    if panel.winnr and vim.api.nvim_win_is_valid(panel.winnr) then
      vim.api.nvim_win_close(panel.winnr, true)
    end
    panel.winnr = nil
  end
end

compositor.ui.find_active_queryer = function()
  local bufs = utils.get_current_win_bufs()
  for _, bufnr in ipairs(bufs) do
    if compositor.queryer[bufnr] then
      return compositor.queryer[bufnr]
    end
  end
  return nil
end

compositor.ui.cal_position = function(panel_name)
  local layout = compositor.ui.layout
  local is_inspector = (panel_name == "inspector")

  local target_pos = is_inspector and layout.inspector or layout.viewer
  local other_pos = is_inspector and layout.viewer or layout.inspector
  local other_panel = is_inspector and compositor.viewer or compositor.inspector

  if target_pos == 1 then
    return "left", -1
  end
  if target_pos == 3 then
    return "right", -1
  end

  if target_pos == 2 then
    local is_other_valid = other_panel.winnr and vim.api.nvim_win_is_valid(other_panel.winnr)
    if other_pos == 1 then
      return is_other_valid and "right" or "left", is_other_valid and other_panel.winnr or -1
    elseif other_pos == 3 then
      return is_other_valid and "left" or "right", is_other_valid and other_panel.winnr or -1
    end
  end
end

compositor.ui.init_scratch_wins = function(context)
  if context.inspector_open then
    queryer.open_inspector()
  elseif compositor.inspector.winnr and vim.api.nvim_win_is_valid(compositor.inspector.winnr) then
    vim.api.nvim_win_close(compositor.inspector.winnr, true)
    compositor.inspector.winnr = nil
  end

  if context.viewer_open then
    queryer.open_viewer()
  elseif compositor.viewer.winnr and vim.api.nvim_win_is_valid(compositor.viewer.winnr) then
    vim.api.nvim_win_close(compositor.viewer.winnr, true)
    compositor.viewer.winnr = nil
  end
end

compositor.api = {
  set_or_create_inspector = function(context)
    local inspector_bufnr = context.inspector.bufnr
    context.inspector_open = true

    if compositor.inspector.winnr and vim.api.nvim_win_is_valid(compositor.inspector.winnr) then
      vim.api.nvim_win_set_buf(compositor.inspector.winnr, inspector_bufnr)
    else
      local split, win = compositor.ui.cal_position("inspector")
      compositor.inspector.winnr = vim.api.nvim_open_win(inspector_bufnr, false, { split = split, win = win })
    end

    return compositor.inspector.winnr
  end,
  set_or_create_viewer = function(context)
    local viewer_bufnr = context.viewer.bufnr
    context.viewer_open = true

    if compositor.viewer.winnr and vim.api.nvim_win_is_valid(compositor.viewer.winnr) then
      vim.api.nvim_win_set_buf(compositor.viewer.winnr, viewer_bufnr)
    else
      local split, win = compositor.ui.cal_position("viewer")
      compositor.viewer.winnr = vim.api.nvim_open_win(viewer_bufnr, false, { split = split, win = win })
    end

    return compositor.viewer.winnr
  end,
  close_inspector = function(context)
    if compositor.inspector.winnr and vim.api.nvim_win_is_valid(compositor.inspector.winnr) then
      vim.api.nvim_win_close(compositor.inspector.winnr, true)
      compositor.inspector.winnr = nil
    end
    context.inspector_open = false
  end,
  close_viewer = function(context)
    if compositor.viewer.winnr and vim.api.nvim_win_is_valid(compositor.viewer.winnr) then
      vim.api.nvim_win_close(compositor.viewer.winnr, true)
      compositor.viewer.winnr = nil
    end
    context.viewer_open = false
  end,
}

local attach_buf = function(conn, bufnr, ui)
  local winnr = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(winnr, bufnr)
  vim.wo.winbar = set_winbar(conn.name)

  local context = {
    conn = conn,
    bufnr = bufnr,
    inspector_open = ui.init_open.inspector,
    viewer_open = ui.init_open.viewer,
  }

  compositor.queryer[bufnr] = context
  queryer.set_context(context)
  queryer.attach_connection()

  compositor.ui.init_scratch_wins(context)
end

local M = {}

local _ui

M.init = function(on_attach, ui)
  compositor.ui.layout = ui.layout
  compositor.ui.validate_layout()
  _ui = ui

  queryer.init(on_attach, compositor.api)

  vim.api.nvim_create_autocmd("BufWinEnter", {
    callback = function(args)
      local context = compositor.queryer[args.buf]
      if context then
        queryer.set_context(context)
        compositor.ui.init_scratch_wins(context)
      else
        if not compositor.ui.find_active_queryer() then
          compositor.ui.suspend_scratch_wins()
        end
      end
    end,
  })

  vim.api.nvim_create_autocmd("BufDelete", {
    callback = function(args)
      queryer.clear_cache()
      compositor.queryer[args.buf] = nil
    end,
  })
end

M.create_queryer = function(conn)
  local bufnr = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_buf_set_name(bufnr, "query_" .. bufnr)
  attach_buf(conn, bufnr, _ui)
end

M.attach_queryer = function(conn, bufnr)
  attach_buf(conn, bufnr, _ui)
end

local toggle_panel = function(panel_key, open_fn)
  local current_buf = vim.api.nvim_get_current_buf()
  local context = compositor.queryer[current_buf]
  local panel = compositor[panel_key]

  if panel.winnr and vim.api.nvim_win_is_valid(panel.winnr) then
    vim.api.nvim_win_close(panel.winnr, true)
    panel.winnr = nil
    if context then
      context[panel_key .. "_open"] = false
    end
  else
    open_fn()
    if context then
      context[panel_key .. "_open"] = true
      vim.api.nvim_set_current_win(compositor[panel_key].winnr)
    end
  end
end

M.toggle_inspector = function()
  toggle_panel("inspector", queryer.open_inspector)
end

M.toggle_viewer = function()
  toggle_panel("viewer", queryer.open_viewer)
end

return M
