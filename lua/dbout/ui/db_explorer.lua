local utils = require("dbout.utils")
local saver = require("dbout.saver")
local rpc = require("dbout.rpc")

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
local node_state = {
  open = "open",
  close = "close",
}

local toggle_state = function(state)
  if state == node_state.open then
    return node_state.close
  else
    return node_state.open
  end
end

local find_root = function(root_id)
  for _, root in ipairs(explorer_tree) do
    if root.id == root_id then
      return root
    end
  end
end

local find_node = function(parent, name)
  for _, child in ipairs(parent.children or {}) do
    if child.name == name then
      return child
    end
  end
end

local add_children = function(parent, list, opts)
  for _, item in ipairs(list) do
    table.insert(parent.children, {
      name = item.name,
      node = opts.node,
      icon = opts.icon,
      state = node_state.close,
      is_selected = false,
      children = {},
    })
  end
end

local create_root = function(connection)
  table.insert(explorer_tree, {
    id = connection.id,
    name = connection.name,
    db_type = connection.db_type,
    connstr = connection.connstr,
    is_connected = false,
    node = "root",
    state = node_state.close,
    children = {},
    icon = "󱘖",
  })
end

local create_db_list = function(root_id, db_list)
  local root = find_root(root_id)
  add_children(root, db_list, {
    node = "db",
    icon = "",
  })
end

local create_table_list = function(root_id, db_name, table_list)
  local root = find_root(root_id)
  local node = find_node(root, db_name)
  add_children(node, table_list, {
    node = "table",
    icon = "",
  })
end

local function find_node_by_line(tree, line, root)
  root = root or nil
  for _, node in ipairs(tree) do
    local current_root = root or node

    if line >= node.first_line and line <= node.last_line then
      if node.children and #node.children > 0 then
        local found_node, found_root = find_node_by_line(node.children, line, current_root)
        if found_node then
          return found_node, found_root
        end
      end
      return node, current_root
    end
  end
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
  local line = 1

  local function render_node(node, depth)
    node.line = line
    node.first_line = line

    local prefix = string.rep("  ", depth)
    local icon = node.icon
    table.insert(lines, prefix .. icon .. " " .. node.name)
    line = line + 1

    if node.state == node_state.open and node.children then
      for _, child in ipairs(node.children) do
        render_node(child, depth + 1)
      end
    end

    node.last_line = line - 1
  end

  for _, root in ipairs(explorer_tree) do
    render_node(root, 0)
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

    local toggle_and_render = function(node)
      node.state = toggle_state(node.state)
      M.render(buf)
    end

    local node, root = find_node_by_line(explorer_tree, current_line)

    if node.node == "root" then
      if root.is_connected then
        toggle_and_render(root)
        return
      end

      rpc.send_jsonrpc("create_connection", {
        id = root.id,
        dbType = root.db_type,
        connStr = root.connstr,
      }, function(data)
        if data ~= "connected" then
          vim.notify(root.name .. " connection failed", vim.log.levels.WARN)
          return
        end

        rpc.send_jsonrpc("get_db_list", {
          id = root.id,
        }, function(db_data)
          root.is_connected = true
          create_db_list(root.id, db_data[1].rows)
          toggle_and_render(root)
        end)
      end)
      return
    end

    if node.node == "db" then
      local db = node
      if db.is_selected then
        toggle_and_render(db)
        return
      end

      rpc.send_jsonrpc("get_table_list", {
        id = root.id,
        dbName = db.name,
      }, function(data)
        db.is_selected = true
        create_table_list(root.id, db.name, data[1].rows)
        toggle_and_render(db)
      end)
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
