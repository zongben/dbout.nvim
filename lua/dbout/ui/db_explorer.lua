local utils = require("dbout.utils")
local saver = require("dbout.saver")

local supported_db = { "mssql", "sqlite" }

local connections = {}
local create_connection = function(tbl)
  return {
    id = utils.generate_uuid(),
    name = tbl.name,
    db_type = tbl.db_type,
    connstr = tbl.connstr,
  }
end

local explorer_tree

local create_root = function(connection)
  table.insert(explorer_tree, {
    id = connection.id,
    name = connection.name,
    db_type = connection.db_type,
    connstr = connection.connstr,
    node = "root",
  })
end

local M = {}

M.init = function()
  explorer_tree = {}
  connections = saver.load() or {}

  for _, conn in ipairs(connections) do
    create_root(conn)
  end
end

M.render = function(buf)
  local lines = {}
  for line, root in ipairs(explorer_tree) do
    root.line = line
    root.first_line = line
    root.last_line = line
    table.insert(lines, root.name)
  end

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
end

M.set_keymaps = function(ui, buf)
  local map = function(mode, key, cb)
    vim.keymap.set(mode, key, cb, { buffer = buf })
  end

  map("n", "<CR>", function()
    local win = vim.api.nvim_get_current_win()
    local current_line = vim.api.nvim_win_get_cursor(win)[1]

    local roots = vim.tbl_filter(function(root)
      return current_line >= root.first_line and current_line <= root.last_line
    end, explorer_tree)

    if #roots == 0 then
      return
    end

    local root = roots[1]
    if current_line == root.line then
      vim.notify(root.name)
      return
    end
  end)

  map("n", "n", function()
    local name = vim.fn.input("Enter name: ")
    if not name then
      return
    end

    vim.ui.select(supported_db, {
      prompt = "choose a database",
    }, function(db_type)
      if not db_type then
        return
      end

      local connstr = vim.fn.input("Enter " .. db_type .. " connection string: ")
      if not connstr then
        return
      end

      local conn = create_connection({
        name = name,
        db_type = db_type,
        connstr = connstr,
      })

      table.insert(connections, conn)
      saver.save(connections)

      create_root(conn)
      M.render(buf)
    end)
  end)

  map("n", "q", function()
    ui.close_db_explorer()
  end)
end

return M
