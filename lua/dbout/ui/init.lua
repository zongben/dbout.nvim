local db_explorer = require("dbout.ui.db_explorer")

local inited = false

local main_buf_name = "dbout://dbout.nvim"
local explorer_buf_name = "dbout://dbout explorer"

local explorer_filetype = "dbout_explorer"
local explorer_buf_var = {
  is_explorer = "is_explorer",
}

local main_bufnr
local explorer_bufnr

local switch_win_to_buf = function(bufnr)
  local win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(win, bufnr)
end

local M = {}

M.open_dbout = function()
  if main_bufnr then
    switch_win_to_buf(main_bufnr)
    return
  end

  main_bufnr = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_buf_set_name(main_bufnr, main_buf_name)
  vim.api.nvim_set_option_value("filetype", "sql", { buf = main_bufnr })
  switch_win_to_buf(main_bufnr)
end

M.open_db_explorer = function()
  if not main_bufnr or main_bufnr ~= vim.api.nvim_get_current_buf() then
    return
  end

  if explorer_bufnr == nil then
    explorer_bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(explorer_bufnr, explorer_buf_name)
    vim.api.nvim_set_option_value("filetype", explorer_filetype, { buf = explorer_bufnr })
    vim.api.nvim_buf_set_var(explorer_bufnr, explorer_buf_var.is_explorer, true)
  end

  vim.cmd("vsplit")
  vim.cmd("vertical resize 30")

  switch_win_to_buf(explorer_bufnr)
  db_explorer.render(explorer_bufnr)
end

M.close_db_explorer = function()
  if explorer_bufnr and vim.api.nvim_buf_is_loaded(explorer_bufnr) then
    vim.api.nvim_buf_delete(explorer_bufnr, { unload = true })
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
      if vim.api.nvim_buf_get_name(buf) == main_buf_name then
        main_bufnr = nil
        return
      end

      if vim.b[buf] and vim.b[buf][explorer_buf_var.is_explorer] then
        explorer_bufnr = nil
        return
      end
    end,
  })

  vim.api.nvim_create_autocmd("FileType", {
    pattern = explorer_filetype,
    callback = function(args)
      local buf = args.buf
      db_explorer.set_keymaps(M, buf)
    end,
  })

  inited = true
end

return M
