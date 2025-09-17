local db_explorer = require("dbout.ui.db_explorer")

local inited = false

local dbout_buf_name = "dbout://dbout.nvim"
local db_explorer_buf_name = "dbout://db explorer"

local db_explorer_filetype = "db_explorer"
local db_explorer_buf_var = {
  is_explorer = "is_explorer",
}

local dbout_bufnr
local db_explorer_bufnr

local switch_win_to_buf = function(bufnr)
  local win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(win, bufnr)
end

local M = {}

M.open_dbout = function()
  if dbout_bufnr then
    switch_win_to_buf(dbout_bufnr)
    return
  end

  dbout_bufnr = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_buf_set_name(dbout_bufnr, dbout_buf_name)
  switch_win_to_buf(dbout_bufnr)
end

M.open_db_explorer = function()
  if not dbout_bufnr or dbout_bufnr ~= vim.api.nvim_get_current_buf() then
    return
  end

  if db_explorer_bufnr == nil then
    db_explorer_bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(db_explorer_bufnr, db_explorer_buf_name)
    vim.api.nvim_set_option_value("filetype", db_explorer_filetype, { buf = db_explorer_bufnr })
    vim.api.nvim_buf_set_var(db_explorer_bufnr, db_explorer_buf_var.is_explorer, true)
  end

  vim.cmd("vsplit")
  vim.cmd("vertical resize 30")

  switch_win_to_buf(db_explorer_bufnr)
  db_explorer.render(db_explorer_bufnr)
end

M.close_db_explorer = function()
  if db_explorer_bufnr and vim.api.nvim_buf_is_loaded(db_explorer_bufnr) then
    vim.api.nvim_buf_delete(db_explorer_bufnr, { unload = true })
  end
end

M.is_inited = function()
  return inited
end

M.init = function()
  db_explorer.init()

  vim.api.nvim_create_autocmd({ "BufDelete" }, {
    callback = function(args)
      local buf = args.buf
      if vim.api.nvim_buf_get_name(buf) == dbout_buf_name then
        dbout_bufnr = nil
        return
      end

      if vim.b[buf] and vim.b[buf][db_explorer_buf_var.is_explorer] then
        db_explorer_bufnr = nil
        return
      end
    end,
  })

  vim.api.nvim_create_autocmd("FileType", {
    pattern = "db_explorer",
    callback = function(args)
      local buf = args.buf
      db_explorer.set_keymaps(M, buf)
    end,
  })

  inited = true
end

return M
