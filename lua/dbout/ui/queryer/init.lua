local utils = require("dbout.utils")

local M = {}

M.buffer_mappings = nil

M.create_buf = function(connection)
  local bufnr = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_set_option_value("filetype", "sql", { buf = bufnr })
  vim.api.nvim_buf_set_var(bufnr, "connection_id", connection.id)
  vim.api.nvim_buf_set_var(bufnr, "connection_name", connection.name)

  M.buffer_mappings(bufnr)

  vim.api.nvim_create_autocmd("BufEnter", {
    buffer = bufnr,
    callback = function(args)
      local connection_name = vim.api.nvim_buf_get_var(args.buf, "connection_name")
      vim.wo.winbar = connection_name
    end,
  })

  utils.switch_win_to_buf(bufnr)
end

return M
