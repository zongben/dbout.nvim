local utils = require("dbout.utils")
local saver = require("dbout.saver")
local node_state = require("dbout.enum").node_state
local node_handlers = require("dbout.ui.explorer.node_handlers")
local explorer_events = require("dbout.enum").explorer_events

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
  node_handlers.init(toggle_and_render)

  local handler = {}

  handler[explorer_events.toggle] = {
    root = node_handlers.toggle_root,
    db = node_handlers.toggle_db,
    folder_tables = node_handlers.toggle_folder_tables,
  }

  return handler
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

    local handler = node_handler[explorer_events.toggle]
    if handler and handler[node.node] then
      handler[node.node](root, node)
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
