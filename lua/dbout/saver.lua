local M = {}

local statepath = vim.fn.stdpath("state")
if type(statepath) == "table" then
  statepath = statepath[1]
end
local state_dir = vim.fs.joinpath(statepath, "dbout")
local persist_file = vim.fs.joinpath(state_dir, "db_explorer.json")

M.save = function(connection)
  local json = vim.fn.json_encode(connection)
  vim.fn.mkdir(state_dir, "p")
  vim.fn.writefile({ json }, persist_file)
end

M.load = function()
  local f = io.open(persist_file, "r")
  if not f then
    return
  end
  local content = f:read("*a")
  f:close()
  return vim.fn.json_decode(content)
end

return M
