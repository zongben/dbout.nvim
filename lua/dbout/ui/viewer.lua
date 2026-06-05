local utils = require("dbout.utils")

local M = {}

M.bufnr = nil

M.buffer_keymappings = nil

M.open_viewer = function(jsonstr)
  if M.bufnr == nil then
    M.bufnr = vim.api.nvim_create_buf(false, true)
    M.buffer_keymappings(M.bufnr)
  end
  vim.api.nvim_set_option_value("filetype", "json", { buf = M.bufnr })

  local lines = utils.split_json(jsonstr)
  utils.set_buf_lines(M.bufnr, lines)

  return M.bufnr
end

M.close_viewer = function()
  utils.close_buf_win(M.bufnr)
end

return M
