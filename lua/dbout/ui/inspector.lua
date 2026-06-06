local utils = require("dbout.utils")
local client = require("dbout.client")

local M = {}

M.buffer_keymappings = nil

M.new = function(connection, q_bufnr)
  local winbar = require("dbout.ui.winbar").new()
  local conn = connection
  local queryer_bufnr = q_bufnr
  local inspector_bufnr

  local m = setmetatable({}, {
    __index = function(_, key)
      if key == "bufnr" then
        return inspector_bufnr
      end
    end,
  })

  local init = function()
    if inspector_bufnr == nil then
      inspector_bufnr = vim.api.nvim_create_buf(false, true)
      M.buffer_keymappings(inspector_bufnr, {
        close_inspector = m.close_inspector_win,
        next_tab = m.next_tab,
        previous_tab = m.previous_tab,
        inspect = m.inspect,
        back = m.back,
      })
    end
    vim.api.nvim_set_option_value("filetype", "json", { buf = inspector_bufnr })
    vim.api.nvim_set_option_value("modifiable", false, { buf = inspector_bufnr })
    m.set_inspector_buf()
  end

  local updateInspector = function(fn)
    if not inspector_bufnr or not vim.api.nvim_buf_is_valid(inspector_bufnr) then
      return
    end
    vim.api.nvim_set_option_value("modifiable", true, { buf = inspector_bufnr })
    fn()
    vim.api.nvim_set_option_value("modifiable", false, { buf = inspector_bufnr })
  end

  local refresh_inspector_view = function(winbar_action)
    winbar_action()
    local winnr = utils.get_buf_win(inspector_bufnr)
    if not winnr then
      vim.notify("No inspector window found", vim.log.levels.ERROR)
      return
    end
    winbar.set_winbar(winnr)
    m.set_inspector_buf()
  end

  local generic_inspect = function(opts)
    opts.list_fn(conn.id, function(jsonstr)
      local data = vim.fn.json_decode(jsonstr)
      vim.ui.select(data.rows, {
        prompt = opts.prompt,
        format_item = function(item)
          return item[opts.name_key]
        end,
      }, function(selected_item)
        if not selected_item then
          return
        end

        opts.detail_fn(conn.id, selected_item[opts.name_key], function(detail_jsonstr)
          local rows = vim.fn.json_decode(detail_jsonstr).rows
          if rows and rows[1] and rows[1].definition then
            local lines = vim.split(rows[1].definition, "\r?\n")
            utils.set_buf_lines(queryer_bufnr, lines)
          end
        end)
      end)
    end)
  end

  local inspect_handlers = {
    Tables = function()
      client.get_table_list(conn.id, function(jsonstr)
        local data = vim.fn.json_decode(jsonstr)
        vim.ui.select(data.rows, {
          prompt = "Inspect a table",
          format_item = function(item)
            return item.table_name
          end,
        }, function(t)
          if not t then
            return
          end
          local winnr = utils.get_buf_win(inspector_bufnr)
          if not winnr then
            vim.notify("No inspector window found", vim.log.levels.ERROR)
            return
          end
          vim.api.nvim_win_set_buf(winnr, inspector_bufnr)
          winbar.set_sub_tab_table(t.table_name)
          winbar.tab_switch(2)
          winbar.set_winbar(winnr)
          m.set_inspector_buf()
        end)
      end)
    end,

    Views = function()
      generic_inspect({
        prompt = "Inspect a view",
        name_key = "view_name",
        list_fn = client.get_view_list,
        detail_fn = client.get_view,
      })
    end,

    StoreProcedures = function()
      if conn.db_type == "sqlite3" then
        return
      end
      generic_inspect({
        prompt = "Inspect a store procedure",
        name_key = "procedure_name",
        list_fn = client.get_store_procedure_list,
        detail_fn = client.get_store_procedure,
      })
    end,

    Functions = function()
      if conn.db_type == "sqlite3" then
        return
      end
      generic_inspect({
        prompt = "Inspect a function",
        name_key = "function_name",
        list_fn = client.get_function_list,
        detail_fn = client.get_function,
      })
    end,

    Triggers = function()
      client.get_trigger_list(conn.id, winbar.get_sub_tab_table(), function(jsonstr)
        local data = vim.fn.json_decode(jsonstr)
        vim.ui.select(data.rows, {
          prompt = "Inspect a trigger",
          format_item = function(item)
            return item.trigger_name
          end,
        }, function(t)
          if not t then
            return
          end
          client.get_trigger(conn.id, t.trigger_name, function(t_jsonstr)
            local rows = vim.fn.json_decode(t_jsonstr).rows
            if rows and rows[1] and rows[1].definition then
              local lines = vim.split(rows[1].definition, "\r?\n")
              utils.set_buf_lines(queryer_bufnr, lines)
            end
          end)
        end)
      end)
    end,

    Columns = function()
      local methods = { "SELECT", "INSERT", "UPDATE" }
      vim.ui.select(methods, { prompt = "Inspect a method" }, function(method)
        if not method then
          return
        end
        local fn = function(s_jsonstr)
          local sql = vim.fn.json_decode(s_jsonstr)
          local lines = vim.split(sql, "\r?\n")
          utils.set_buf_lines(queryer_bufnr, lines)
        end

        if method == "SELECT" then
          client.generate_select_sql(conn.id, winbar.get_sub_tab_table(), fn)
        elseif method == "UPDATE" then
          client.generate_update_sql(conn.id, winbar.get_sub_tab_table(), fn)
        elseif method == "INSERT" then
          client.generate_insert_sql(conn.id, winbar.get_sub_tab_table(), fn)
        end
      end)
    end,
  }

  m.set_inspector_buf = function()
    local tab = winbar.get_current_tab()
    local fn = function(jsonstr)
      local lines = utils.split_json(jsonstr)
      updateInspector(function()
        utils.set_buf_lines(inspector_bufnr, lines)
      end)
    end

    if tab == "Tables" then
      client.get_table_list(conn.id, fn)
    elseif tab == "Views" then
      client.get_view_list(conn.id, fn)
    elseif tab == "StoreProcedures" then
      client.get_store_procedure_list(conn.id, fn)
    elseif tab == "Functions" then
      client.get_function_list(conn.id, fn)
    elseif tab == "Columns" then
      client.get_table(conn.id, winbar.get_sub_tab_table(), fn)
    elseif tab == "Triggers" then
      client.get_trigger_list(conn.id, winbar.get_sub_tab_table(), fn)
    end
  end

  m.set_winbar = function(winnr)
    if winnr and vim.api.nvim_win_is_valid(winnr) then
      vim.api.nvim_win_set_buf(winnr, inspector_bufnr)
      winbar.set_winbar(winnr)
    end
  end

  m.reset = function()
    utils.close_buf_win(inspector_bufnr)
    winbar.reset()
  end

  m.close_inspector_win = function()
    utils.close_buf_win(inspector_bufnr)
  end

  m.next_tab = function()
    refresh_inspector_view(winbar.next_tab)
  end
  m.previous_tab = function()
    refresh_inspector_view(winbar.previous_tab)
  end
  m.back = function()
    refresh_inspector_view(winbar.back)
  end

  m.inspect = function()
    local tab = winbar.get_current_tab()
    local handler = inspect_handlers[tab]
    if handler then
      handler()
    end
  end

  init()

  return m
end

return M
