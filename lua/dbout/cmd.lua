local rpc = require("dbout.rpc")
local ui = require("dbout.ui")

local M = {}

M.init = function()
  vim.api.nvim_create_user_command("Dbout", function()
    if not rpc.is_alive() then
      rpc.server_up()
    end

    ui.init()
    ui.open_dbout()
    ui.open_db_explorer()
  end, {})
end

return M
