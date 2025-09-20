local explorer = require("dbout.ui.explorer")
local main = require("dbout.ui.main")
local utils = require("dbout.utils")

local inited = false

local main_buf_name = "dbout://dbout.nvim"
local explorer_buf_name = "dbout://dbout explorer"

local explorer_filetype = "dbout_explorer"
local explorer_buf_var = {
  is_explorer = "is_explorer",
}

local main_bufnr
local explorer_bufnr

local M = {}

M.open_dbout = function()
  if main_bufnr == nil then
    main_bufnr = vim.api.nvim_create_buf(true, false)
    vim.api.nvim_buf_set_name(main_bufnr, main_buf_name)
    vim.api.nvim_set_option_value("filetype", "sql", { buf = main_bufnr })
    main.set_keymaps(main_bufnr)
  end

  utils.switch_win_to_buf(main_bufnr)
end

M.open_db_explorer = function()
  if main_bufnr == nil then
    return
  end

  if explorer_bufnr == nil then
    explorer_bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(explorer_bufnr, explorer_buf_name)
    vim.api.nvim_buf_set_var(explorer_bufnr, explorer_buf_var.is_explorer, true)

    vim.api.nvim_set_option_value("filetype", explorer_filetype, { buf = explorer_bufnr })
    vim.api.nvim_set_option_value("modifiable", false, { buf = explorer_bufnr })

    explorer.set_keymaps(M, explorer_bufnr)
  end

  if vim.fn.bufwinnr(explorer_bufnr) == -1 then
    vim.cmd("vsplit")
    vim.cmd("vertical resize 30")
    explorer.render(explorer_bufnr)
  end

  utils.switch_win_to_buf(explorer_bufnr)
end

M.close_db_explorer = function()
  if explorer_bufnr and vim.api.nvim_buf_is_loaded(explorer_bufnr) then
    local wins = vim.fn.win_findbuf(explorer_bufnr)
    if #wins > 0 then
      vim.api.nvim_win_close(wins[1], true)
    end
  end
end

M.is_inited = function()
  return inited
end

M.init = function()
  explorer.init()

  vim.api.nvim_create_autocmd({ "BufDelete" }, {
    callback = function(args)
      local buf = args.buf
      if vim.api.nvim_buf_get_name(buf) == main_buf_name then
        main_bufnr = nil
        return
      end
    end,
  })

  inited = true
end

return M
