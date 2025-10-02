local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local action_state = require("telescope.actions.state")
local actions = require("telescope.actions")
local conf = require("telescope.config").values
local entry_display = require("telescope.pickers.entry_display")
local conn = require("dbout.connection")
local utils = require("dbout.utils")

local M = {}

M.picker_mappings = nil

local create_connection_buffer = function(connection)
  local bufnr = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_set_option_value("filetype", "sql", { buf = bufnr })
  vim.api.nvim_buf_set_var(bufnr, "connection_id", connection.id)
  vim.api.nvim_buf_set_var(bufnr, "connection_name", connection.name)

  local lsp_name = "sqls" .. "_" .. connection.db_type .. "_" .. connection.name
  vim.lsp.config[lsp_name] = {
    cmd = { "sqls" },
    filetypes = { "sql" },
    settings = {
      sqls = {
        connections = {
          {
            driver = connection.db_type,
            dataSourceName = connection.connstr,
          },
        },
      },
    },
  }
  vim.lsp.enable(lsp_name, true)

  vim.api.nvim_create_autocmd("BufEnter", {
    buffer = bufnr,
    callback = function(args)
      local connection_name = vim.api.nvim_buf_get_var(args.buf, "connection_name")
      vim.wo.winbar = connection_name
    end,
  })

  utils.switch_win_to_buf(bufnr)
end

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
          create_connection_buffer(selection.value)
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

local create_connection = function(connection, cb)
  local name = vim.fn.input("Enter name: ", connection.name or "")
  if not name then
    return
  end

  if conn.is_conn_exists(connection.id or "", name) then
    vim.notify(name .. " is used.", vim.log.levels.ERROR)
    return
  end

  vim.ui.select(conn.get_supported_db(), {
    prompt = "Choose a database",
  }, function(db_type)
    if not db_type then
      return
    end

    local connstr = vim.fn.input("Enter " .. db_type .. " connection string: ", connection.connstr or "")
    if not connstr then
      return
    end

    local c = conn.create_connection(name, db_type, connstr)
    cb(c)
  end)
end

M.open_connection_picker = function()
  new_picker()
end

M.new_connection = function(prompt_bufnr)
  create_connection({}, function(c)
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
  create_connection(connection, function(c)
    conn.update_connection(c)
    refresh_picker(prompt_bufnr)
  end)
end

return M
