local rpc = require("dbout.rpc")
local conn = require("dbout.connection")
local queryer = require("dbout.ui.queryer")

local args = {
  new_connection = "NewConnection",
  edit_connection = "EditConnection",
  delete_connection = "DeleteConnection",
  open_connection = "OpenConnection",
}

local select_connection = function(cb)
  vim.ui.select(conn.get_connections(), {
    prompt = "Choose a connection",
    format_item = function(item)
      return item.name .. " " .. item.db_type .. ":" .. item.connstr
    end,
  }, function(connection)
    if not connection then
      return
    end
    cb(connection)
  end)
end

local new_connection = function()
  conn.create_connection({}, function(c)
    conn.add_connection(c)
  end)
end

local edit_connection = function()
  select_connection(function(c)
    conn.create_connection(c, function(cn)
      conn.update_connection(cn)
    end)
  end)
end

local delete_connection = function()
  select_connection(function(c)
    conn.remove_connection(c.id)
  end)
end

local open_connection = function()
  select_connection(function(c)
    conn.open_connection(c, function()
      queryer.create_buf(c)
    end)
  end)
end

local M = {}

M.init = function(enable_telescope)
  vim.api.nvim_create_user_command("Dbout", function(opts)
    if not rpc.is_alive() then
      rpc.server_up()
    end

    if enable_telescope then
      local tele = require("dbout.tele")
      tele.open_connection_picker()
    end

    local cmd = opts.args
    if cmd == args.new_connection then
      new_connection()
    elseif cmd == args.edit_connection then
      edit_connection()
    elseif cmd == args.delete_connection then
      delete_connection()
    elseif cmd == args.open_connection then
      open_connection()
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
