local viewer_bufnr

local M = {}

M.open_viewer = function(json_data)
  if viewer_bufnr == nil then
    viewer_bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_option_value("filetype", "json", { buf = viewer_bufnr })
  end

  vim.cmd("vsplit")
  vim.cmd("wincmd L")

  vim.api.nvim_win_set_buf(0, viewer_bufnr)

  local formatted = vim.fn.system({ "jq", ".", "-M" }, vim.fn.json_encode(json_data))
  local lines = vim.split(formatted, "\n", { plain = true })
  vim.api.nvim_buf_set_lines(viewer_bufnr, 0, -1, false, lines)
end

return M
