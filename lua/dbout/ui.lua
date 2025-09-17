local inited = false

local dbout_buf_name = "dbout://dbout.nvim"
local dbout_bufnr
local db_explorer_buf_name = "dbout://db explorer"
local db_explorer_buf_var = "is_db_explorer"
local db_explorer_bufnr

local switch_win_to_buf = function(bufnr)
  local win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(win, bufnr)
end

local is_dbout_buf = function()
  return dbout_bufnr == vim.api.nvim_get_current_buf()
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
  if not is_dbout_buf() then
    return
  end

  if db_explorer_bufnr == nil then
    db_explorer_bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(db_explorer_bufnr, db_explorer_buf_name)
    vim.api.nvim_set_option_value("filetype", "db_explorer", { buf = db_explorer_bufnr })
    vim.api.nvim_buf_set_var(db_explorer_bufnr, db_explorer_buf_var, true)
  end

  vim.cmd("vsplit")
  vim.cmd("vertical resize 30")

  switch_win_to_buf(db_explorer_bufnr)
end

M.init = function()
  if inited then
    return
  else
    inited = true
  end

  vim.api.nvim_create_autocmd({ "BufDelete" }, {
    callback = function(args)
      local buf = args.buf
      local buf_name = vim.api.nvim_buf_get_name(buf)
      if buf_name == dbout_buf_name then
        dbout_bufnr = nil
        return
      end

      if vim.b[buf] and vim.b[buf][db_explorer_buf_var] then
        db_explorer_bufnr = nil
        return
      end
    end,
  })

  vim.api.nvim_create_autocmd("FileType", {
    pattern = "db_explorer",
    callback = function(args)
      local buf = args.buf
      vim.keymap.set("n", "n", function()
        vim.ui.select({ "mssql", "sqlite" }, {
          prompt = "choose a database",
        }, function(item)
          vim.notify("you choose " .. item)
        end)
      end, { buffer = buf })
    end,
  })
end

return M
