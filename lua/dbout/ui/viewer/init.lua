local viewer_bufnr

local M = {}

M.open_viewer = function(json_data)
  if viewer_bufnr == nil then
    viewer_bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_option_value("filetype", "json", { buf = viewer_bufnr })
  end

  local formatted = vim.fn.system({ "jq", ".", "-M" }, vim.fn.json_encode(json_data))
  local lines = vim.split(formatted, "\n", { plain = true })
  vim.api.nvim_buf_set_lines(viewer_bufnr, 0, -1, false, lines)

  local wins = vim.fn.win_findbuf(viewer_bufnr)
  local winnr
  if #wins == 0 then
    vim.cmd("botright vsplit")
    winnr = 0
  else
    winnr = wins[1]
  end

  vim.api.nvim_win_set_buf(winnr, viewer_bufnr)
end

return M
