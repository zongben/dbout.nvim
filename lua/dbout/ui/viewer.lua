local utils = require("dbout.utils")

local viewer_bufnr

local M = {}

M.buffer_keymappings = nil

local open_viewer = function(fn)
  if viewer_bufnr == nil then
    viewer_bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_option_value("filetype", "json", { buf = viewer_bufnr })
    M.buffer_keymappings(viewer_bufnr)
  end

  fn()

  local wins = vim.fn.win_findbuf(viewer_bufnr)
  local winnr
  if #wins == 0 then
    vim.cmd("botright vsplit")
    winnr = vim.api.nvim_get_current_win()
  else
    winnr = wins[1]
  end
  vim.api.nvim_win_set_buf(winnr, viewer_bufnr)
end

M.open_query_result = function(data)
  open_viewer(function()
    local formatted = vim.fn.system({ "jq", ".", "-M" }, data)
    local lines = vim.split(formatted, "\n", { plain = true })
    vim.api.nvim_buf_set_lines(viewer_bufnr, 0, -1, false, lines)
  end)
end

M.close_viewer = function()
  utils.close_buf_win(viewer_bufnr)
end

return M
