local rpc = require("dbout.rpc")
local ui = require("dbout.ui")

local args = {
  open_db_explorer = "OpenDbExplorer",
  close_db_explorer = "CloseDbExplorer",
}

local M = {}

M.init = function()
  vim.api.nvim_create_user_command("Dbout", function(opts)
    local cmd = opts.args

    if cmd == "" then
      if not rpc.is_alive() then
        rpc.server_up()
      end
      if not ui.is_inited() then
        ui.init()
      end
      ui.open_dbout()
      return
    end

    if not ui.is_inited() then
      return
    end

    if cmd == args.open_db_explorer then
      ui.open_db_explorer()
    elseif cmd == args.close_db_explorer then
      ui.close_db_explorer()
    end
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
