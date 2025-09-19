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

local create_node = function(parent, children, format)
  local format_children = {}
  for _, child in ipairs(children) do
    table.insert(format_children, format(child))
  end
  parent.children = format_children
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

local create_node_handler = function(buf)
  local function toggle_and_render(node)
    node.state = toggle_state(node.state)
    M.render(buf)
  end

  local node_handler = {}

  node_handler["root"] = function(root, _)
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
        create_node(root, db_data[1].rows, function(db)
          return {
            name = db.name,
            node = "db",
            icon = "",
            state = node_state.close,
            is_selected = false,
            children = {},
          }
        end)
        toggle_and_render(root)
      end)
    end)
  end

  node_handler["db"] = function(_, node)
    local db = node
    if db.is_selected then
      toggle_and_render(db)
      return
    end

    db.is_selected = true
    create_node(db, {
      { name = "tables" },
      { name = "views" },
    }, function(folder)
      return {
        name = folder.name,
        node = "folder" .. "_" .. folder.name,
        icon = "",
        state = node_state.close,
        is_selected = false,
        children = {},
        parent = db.name,
      }
    end)
    toggle_and_render(db)
  end

  node_handler["folder_tables"] = function(root, node)
    local folder = node
    if folder.is_selected then
      toggle_and_render(folder)
      return
    end

    rpc.send_jsonrpc("get_table_list", {
      id = root.id,
      dbName = folder.parent,
    }, function(data)
      folder.is_selected = true
      create_node(folder, data[1].rows, function(table)
        return {
          name = table.name,
          node = "table",
          icon = "",
          state = node_state.close,
          is_selected = false,
          children = {},
        }
      end)
      toggle_and_render(folder)
    end)
  end

  return node_handler
end

M.set_keymaps = function(ui, buf)
  local map = function(mode, key, cb)
    vim.keymap.set(mode, key, cb, { buffer = buf })
  end

  local node_handler = create_node_handler(buf)

  map("n", "<CR>", function()
    local win = vim.api.nvim_get_current_win()
    local current_line = vim.api.nvim_win_get_cursor(win)[1]

    local node, root = find_node_by_line(explorer_tree, current_line)
    if not node then
      return
    end

    local handler = node_handler[node.node]
    if handler then
      handler(root, node)
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
