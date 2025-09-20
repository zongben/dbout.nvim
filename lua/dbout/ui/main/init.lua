local rpc = require("dbout.rpc")
local viewer = require("dbout.ui.viewer")

local M = {}

M.set_keymaps = function(buf)
  local map = function(mode, key, cb)
    vim.keymap.set(mode, key, cb, { buffer = buf })
  end

  map("n", "<F5>", function()
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

return M
