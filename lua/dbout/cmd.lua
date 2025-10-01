local rpc = require("dbout.rpc")
local tele = require("dbout.tele")

local args = {}

local M = {}

M.init = function()
  vim.api.nvim_create_user_command("Dbout", function()
    if not rpc.is_alive() then
      rpc.server_up()
    end

    tele.open_connection_picker()
  end, {
    nargs = "?",
    complete = function(_, line, pos)
      local arg = line:sub(pos + 1)
      local matches = {}
      for _, opt in pairs(args) do
        if opt:match("^" .. arg) then
          table.insert(matches, opt)
        end
      end
      return matches
    end,
  })
end

return M
