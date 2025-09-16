local rpc = require("dbout.rpc")
local ui = require("dbout.ui")

local M = {}

M.init = function()
  vim.api.nvim_create_user_command("Dbout", function()
    if not rpc.is_alive() then
      rpc.server_up()
    end

    ui.init()
  end, {})
end

return M
