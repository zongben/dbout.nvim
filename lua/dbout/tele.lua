local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local action_state = require("telescope.actions.state")
local actions = require("telescope.actions")
local conf = require("telescope.config").values
local entry_display = require("telescope.pickers.entry_display")
local conn = require("dbout.connection")
local queryer = require("dbout.ui.queryer")

local M = {}

M.picker_mappings = nil

local function create_finder(connections)
  local displayer = entry_display.create({
    separator = " ",
    items = {
      {
        width = 15,
      },
      {
        remaining = true,
      },
    },
  })

  local function make_display(entry)
    return displayer({ entry.name, { entry.value.db_type .. ":" .. entry.value.connstr, "Comment" } })
  end

  return finders.new_table({
    results = connections,
    entry_maker = function(entry)
      return {
        display = make_display,
        name = entry.name,
        value = entry,
        ordinal = entry.name,
      }
    end,
  })
end

local new_picker = function()
  pickers
    .new({}, {
      prompt_title = "Connections",
      finder = create_finder(conn.get_connections()),
      sorter = conf.generic_sorter({}),
      attach_mappings = function(_, map)
        actions.select_default:replace(function(prompt_bufnr)
          local selection = action_state.get_selected_entry()
          if not selection then
            return false
          end

          local connection = selection.value
          conn.open_connection(connection, function()
            actions.close(prompt_bufnr)
            queryer.create_buf(connection)
          end)
        end)
        if M.picker_mappings then
          M.picker_mappings(map)
        end
        return true
      end,
    })
    :find()
end

local refresh_picker = function(prompt_bufnr)
  local picker = action_state.get_current_picker(prompt_bufnr)
  if picker then
    local finder = create_finder(conn.get_connections())
    picker:refresh(finder)
  else
    M.open_connection_picker()
  end
end

M.open_connection_picker = function()
  new_picker()
end

M.new_connection = function(prompt_bufnr)
  conn.create_connection({}, function(c)
    conn.add_connection(c)
    refresh_picker(prompt_bufnr)
  end)
end

M.delete_connection = function(prompt_bufnr)
  local connection = action_state.get_selected_entry().value
  conn.remove_connection(connection.id)
  refresh_picker(prompt_bufnr)
end

M.edit_connection = function(prompt_bufnr)
  local connection = action_state.get_selected_entry().value
  conn.create_connection(connection, function(c)
    conn.update_connection(c)
    refresh_picker(prompt_bufnr)
  end)
end

return M
