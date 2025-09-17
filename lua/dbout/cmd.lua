local rpc = require("dbout.rpc")
local ui = require("dbout.ui")

local M = {}

M.init = function()
  vim.api.nvim_create_user_command("Dbout", function(opts)
    if not rpc.is_alive() then
      rpc.server_up()
    end

    ui.init()

    local cmd = opts.args
    if cmd == "OpenDbExplorer" then
      ui.open_db_explorer()
    elseif cmd == "CloseDbExplorer" then
      ui.close_db_explorer()
    else
      ui.open_dbout()
    end
  end, {
    nargs = "?",
    complete = function(_, line, pos)
      local options = { "OpenDbExplorer", "CloseDbExplorer" }
      local arg = line:sub(pos + 1)
      local matches = {}
      for _, opt in ipairs(options) do
        if opt:match("^" .. arg) then
          table.insert(matches, opt)
        end
      end
      return matches
    end,
  })
end

return M
