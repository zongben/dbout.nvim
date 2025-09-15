local client = require("dbout.rpc_client")

local M = {}

M.setup = function()
  client.init()
end

return M
