local dbout_bufnr
local db_explorer_bufnr

local M = {}

M.open_dbout = function()
  if dbout_bufnr then
    vim.api.nvim_set_current_buf(dbout_bufnr)
  else
    dbout_bufnr = vim.api.nvim_create_buf(true, false)
    vim.api.nvim_buf_set_name(dbout_bufnr, "dbout.nvim")
    vim.api.nvim_set_current_buf(dbout_bufnr)
  end
end

M.open_db_explorer = function()
  db_explorer_bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(db_explorer_bufnr, "db explorer")

  vim.cmd("vsplit")
  vim.cmd("vertical resize 30")

  local win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(win, db_explorer_bufnr)
end

M.init = function()
  M.open_dbout()
  M.open_db_explorer()
end

return M
