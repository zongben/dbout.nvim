local conn = require("dbout.connection")
local queryer = require("dbout.ui.queryer")

local function truncate(text, width)
  if #text > width then
    return text:sub(1, width - 1) .. "…"
  end
  return text
end

local options = {
  keymaps = {
    open_connection = "<cr>",
    new_connection = "n",
    delete_connection = "d",
    edit_connection = "e",
    attach_connection = "a",
  },
}

local M = {}

M.setup = function(opts)
  options = vim.tbl_deep_extend("force", options, opts or {})
end

M.open_picker = function()
  ---@class snacks.picker.Config
  local config = {
    source = "dbout",
    title = "Connections",
    preview = "none",
    layout = {
      preset = "select",
    },
    finder = function()
      local items = {}
      for index, value in ipairs(conn.get_connections()) do
        table.insert(items, {
          idx = index,
          name = value.name,
          text = value.name,
          id = value.id,
          connstr = value.connstr,
          db_type = value.db_type,
        })
      end
      return items
    end,
    format = function(item)
      return {
        { string.format("%-15s", truncate(item.name, 15)) },
        { item.db_type .. ":" .. item.connstr, "SnacksPickerComment" },
      }
    end,
    win = {
      input = {
        keys = {
          [options.keymaps.open_connection] = { "open_connection", mode = { "n" } },
          [options.keymaps.new_connection] = { "new_connection", mode = { "n" } },
          [options.keymaps.delete_connection] = { "delete_connection", mode = { "n" } },
          [options.keymaps.edit_connection] = { "edit_connection", mode = { "n" } },
          [options.keymaps.attach_connection] = { "attach_connection", mode = { "n" } },
        },
      },
    },
    actions = {
      confirm = function() end,
      new_connection = function(picker)
        picker:close()
        conn.create_connection({}, function(c)
          conn.add_connection(c)
          M.open_picker()
        end)
      end,
      delete_connection = function(picker, item)
        conn.remove_connection(item.id)
        picker:find()
      end,
      edit_connection = function(picker, item)
        conn.create_connection(item, function(c)
          conn.update_connection(c)
          picker:find()
        end)
      end,
      open_connection = function(picker, item)
        conn.open_connection(item, function()
          picker:close()
          queryer.create_buf(item)
        end)
      end,
      attach_connection = function(picker, item)
        conn.open_connection(item, function()
          picker:close()
          queryer.attach_buf(item, vim.api.nvim_get_current_buf())
        end)
      end,
    },
  }

  Snacks.picker.pick(config)
end

return M
