local rpc = require("dbout.rpc")
local viewer = require("dbout.ui.viewer")
local utils = require("dbout.utils")

local main_bufnr
local main_buf_name = "dbout://dbout.nvim"

local M = {}

M.init = function()
  vim.api.nvim_create_autocmd({ "BufDelete" }, {
    callback = function(args)
      local buf = args.buf
      if vim.api.nvim_buf_get_name(buf) == main_buf_name then
        main_bufnr = nil
        return
      end
    end,
  })
end

M.set_keymaps = function(buf)
  local map = function(mode, key, cb)
    vim.keymap.set(mode, key, cb, { buffer = buf })
  end

  map({ "n", "i", "v" }, "<F5>", function()
    local win = vim.api.nvim_get_current_win()
    local bufnr = vim.api.nvim_win_get_buf(win)
    local root_id = vim.api.nvim_buf_get_var(bufnr, "root_id")
    -- local db_name = vim.api.nvim_buf_get_var(bufnr, "db_name")

    local sql = table.concat(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), "\n")

    rpc.send_jsonrpc("query", {
      id = root_id,
      sql = sql,
    }, function(data)
      viewer.open_viewer(data)
    end)
  end)
end

M.open_dbout = function()
  if main_bufnr == nil then
    main_bufnr = vim.api.nvim_create_buf(true, false)
    vim.api.nvim_buf_set_name(main_bufnr, main_buf_name)
    vim.api.nvim_set_option_value("filetype", "sql", { buf = main_bufnr })
    M.set_keymaps(main_bufnr)
  end

  utils.switch_win_to_buf(main_bufnr)
end

return M
