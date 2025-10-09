local utils = require("dbout.utils")

local viewer_bufnr

local M = {}

M.buffer_keymappings = nil

M.open_viewer = function(jsonstr)
  if viewer_bufnr == nil then
    viewer_bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_option_value("filetype", "json", { buf = viewer_bufnr })
    M.buffer_keymappings(viewer_bufnr)
  end

  local lines = utils.format_json(jsonstr)
  utils.set_buf_lines(viewer_bufnr, lines)

  local winnr = utils.get_or_create_buf_win(viewer_bufnr)
  vim.api.nvim_win_set_buf(winnr, viewer_bufnr)
  vim.api.nvim_set_option_value("winbar", "%#Title#[Query Result]%*", { win = winnr })
end

M.close_viewer = function()
  utils.close_buf_win(viewer_bufnr)
end

return M
