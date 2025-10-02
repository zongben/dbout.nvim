local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local action_state = require("telescope.actions.state")
local actions = require("telescope.actions")
local conf = require("telescope.config").values
local entry_display = require("telescope.pickers.entry_display")
local conn = require("dbout.connection")
local utils = require("dbout.utils")

local supported_db = { "mssql", "sqlite" }

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
    return displayer({ entry.name, { entry.value.connstr, "Comment" } })
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
          actions.close(prompt_bufnr)

          --when selected
          --logic here
          --
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
  local finder = create_finder(conn.get_connections())
  action_state.get_current_picker(prompt_bufnr):refresh(finder)
end

M.open_connection_picker = function()
  new_picker()
end

M.create_connection = function(prompt_bufnr)
  local name = vim.fn.input("Enter name: ")
  if not name then
    return
  end

  for _, c in ipairs(conn.connections) do
    if c.name == name then
      vim.notify(name .. " is used.", vim.log.levels.ERROR)
      return
    end
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

    conn.add_connection({
      id = utils.generate_uuid(),
      name = name,
      db_type = db_type,
      connstr = connstr,
    })

    refresh_picker(prompt_bufnr)
  end)
end

M.delete_connection = function(prompt_bufnr)
  local selection = action_state.get_selected_entry()
  conn.remove_connection(selection.value.id)
  refresh_picker(prompt_bufnr)
end

return M
