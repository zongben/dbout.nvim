local utils = require("dbout.utils")
local client = require("dbout.client")

local M = {}

M.buffer_keymappings = nil

--- @return Inspector
M.new = function()
  local winbar = require("dbout.ui.winbar").new()
  local inspector_bufnr
  local conn
  local queryer_bufnr

  local updateInspector = function(fn)
    vim.api.nvim_set_option_value("modifiable", true, { buf = inspector_bufnr })
    fn()
    vim.api.nvim_set_option_value("modifiable", false, { buf = inspector_bufnr })
  end

  ---@type Inspector
  ---@diagnostic disable-next-line: missing-fields
  local m = {}

  m.bufnr = inspector_bufnr

  local set_inspector_buf = function()
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

  local inspect_view = function()
    client.get_view_list(conn.id, function(jsonstr)
      local data = vim.fn.json_decode(jsonstr)
      vim.ui.select(data.rows, {
        prompt = "Inspect a view",
        format_item = function(item)
          return item.view_name
        end,
      }, function(view)
        if not view then
          return
        end
        client.get_view(conn.id, view.view_name, function(v_jsonstr)
          local v = vim.fn.json_decode(v_jsonstr).rows[1].definition
          local lines = vim.split(v, "\r?\n")
          utils.set_buf_lines(queryer_bufnr, lines)
        end)
      end)
    end)
  end

  local inspect_store_procedure = function()
    client.get_store_procedure_list(conn.id, function(jsonstr)
      local data = vim.fn.json_decode(jsonstr)
      vim.ui.select(data.rows, {
        prompt = "Inspect a store procedure",
        format_item = function(item)
          return item.procedure_name
        end,
      }, function(procedure)
        if not procedure then
          return
        end
        client.get_store_procedure(conn.id, procedure.procedure_name, function(sp_jsonstr)
          local sp = vim.fn.json_decode(sp_jsonstr).rows[1].definition
          local lines = vim.split(sp, "\r?\n")
          utils.set_buf_lines(queryer_bufnr, lines)
        end)
      end)
    end)
  end

  local inspect_function = function()
    client.get_function_list(conn.id, function(jsonstr)
      local data = vim.fn.json_decode(jsonstr)
      vim.ui.select(data.rows, {
        prompt = "Inspect a function",
        format_item = function(item)
          return item.function_name
        end,
      }, function(f)
        if not f then
          return
        end
        client.get_function(conn.id, f.function_name, function(f_jsonstr)
          local sp = vim.fn.json_decode(f_jsonstr).rows[1].definition
          local lines = vim.split(sp, "\r?\n")
          utils.set_buf_lines(queryer_bufnr, lines)
        end)
      end)
    end)
  end

  local inspect_table = function()
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
        local winnr = utils.get_or_create_buf_win(inspector_bufnr)
        vim.api.nvim_win_set_buf(winnr, inspector_bufnr)
        winbar.set_sub_tab_table(t.table_name)
        winbar.tab_switch(2)
        winbar.set_winbar(winnr)
        set_inspector_buf()
      end)
    end)
  end

  local inspect_trigger = function()
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
          local sp = vim.fn.json_decode(t_jsonstr).rows[1].definition
          local lines = vim.split(sp, "\r?\n")
          utils.set_buf_lines(queryer_bufnr, lines)
        end)
      end)
    end)
  end

  local inspect_column = function()
    local methods = {
      "SELECT",
      "INSERT",
      "UPDATE",
    }
    vim.ui.select(methods, {
      prompt = "Inspect a method",
    }, function(method)
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
  end

  m.open_inspector = function(connection, bufnr)
    conn = connection
    queryer_bufnr = bufnr

    if inspector_bufnr == nil then
      inspector_bufnr = vim.api.nvim_create_buf(false, true)
      M.buffer_keymappings(inspector_bufnr, {
        close_inspector = m.close_inspector,
        next_tab = m.next_tab,
        previous_tab = m.previous_tab,
        inspect = m.inspect,
        back = m.back,
      })
    end

    vim.api.nvim_set_option_value("filetype", "json", { buf = inspector_bufnr })
    vim.api.nvim_set_option_value("modifiable", false, { buf = inspector_bufnr })

    set_inspector_buf()

    return inspector_bufnr
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

  m.close_inspector = function()
    utils.close_buf_win(inspector_bufnr)
  end

  m.next_tab = function()
    winbar.next_tab()
    local winnr = utils.get_buf_win(inspector_bufnr)
    if not winnr then
      vim.notify("No inspector window found", vim.log.levels.ERROR)
      return
    end
    winbar.set_winbar(winnr)
    set_inspector_buf()
  end

  m.previous_tab = function()
    winbar.previous_tab()
    local winnr = utils.get_buf_win(inspector_bufnr)
    if not winnr then
      vim.notify("No inspector window found", vim.log.levels.ERROR)
      return
    end
    winbar.set_winbar(winnr)
    set_inspector_buf()
  end

  m.inspect = function()
    local tab = winbar.get_current_tab()

    if tab == "Tables" then
      inspect_table()
    elseif tab == "Views" then
      inspect_view()
    elseif tab == "StoreProcedures" then
      if conn.db_type == "sqlite3" then
        return
      end
      inspect_store_procedure()
    elseif tab == "Functions" then
      if conn.db_type == "sqlite3" then
        return
      end
      inspect_function()
    elseif tab == "Triggers" then
      inspect_trigger()
    elseif tab == "Columns" then
      inspect_column()
    end
  end

  m.back = function()
    winbar.back()
    local winnr = utils.get_buf_win(inspector_bufnr)
    if not winnr then
      vim.notify("No inspector window found", vim.log.levels.ERROR)
      return
    end
    winbar.set_winbar(winnr)
    set_inspector_buf()
  end

  return m
end

return M
