local utils = require("dbout.utils")

local job_id
local callbacks = {}

local M = {}

M.server_up = function()
  local files = vim.api.nvim_get_runtime_file("server/main.js", false)
  job_id = vim.fn.jobstart({
    "node",
    files[1],
  }, {
    on_stdout = function(_, json)
      local data = vim.fn.json_decode(json)
      if callbacks[data.id] then
        callbacks[data.id](data.result)
        callbacks[data.id] = nil
      end
    end,
    on_stderr = function(_, json)
      local data = vim.fn.json_decode(json)
      if data.id and callbacks[data.id] then
        callbacks[data.id] = nil
      end
      vim.notify(data.error.message .. " " .. data.error.data, vim.log.levels.ERROR)
    end,
  })
end

M.is_alive = function()
  return vim.fn.jobwait({ job_id }, 0)[0] == -1
end

M.send_jsonrpc = function(method, params, cb)
  local id = utils.generate_uuid()
  local jsonrpc = {
    jsonrpc = "2.0",
    id = id,
    method = method,
    params = params,
  }
  callbacks[id] = cb
  local json = vim.fn.json_encode(jsonrpc)
  -- vim.notify(json)
  vim.fn.chansend(job_id, json .. "\n")
end

M.send_notification = function(method, params)
  local jsonrpc = {
    jsonrpc = "2.0",
    method = method,
    params = params,
  }

  vim.fn.chansend(job_id, vim.fn.json_encode(jsonrpc) .. "\n")
end

return M
