local utils = require("dbout.utils")

local _config = {}

local M = {}

M.buffer_keymappings = nil

M.init = function(config)
  _config = config
  if _config.history.limit <= 0 then
    error("Invalid viewer configuration. 'history.limit' must be greater then 0.")
  end
end

M.new = function()
  local viewer_bufnr
  local _winnr

  local ctx = {
    enabled = _config.history.enabled,
    index = 0,
    limit = _config.history.limit,
    histories = {},
  }
  ctx.api = {
    push_history = function(jsonstr)
      table.insert(ctx.histories, 1, { lines = utils.split_json(jsonstr) })
      if #ctx.histories > ctx.limit then
        table.remove(ctx.histories)
      end
      ctx.index = 1
    end,
    next_history = function()
      if ctx.index < #ctx.histories then
        ctx.index = ctx.index + 1
      end
    end,
    previous_history = function()
      if ctx.index > 1 then
        ctx.index = ctx.index - 1
      end
    end,
    get_history = function()
      if ctx.index == 0 then
        return {}
      end
      return ctx.histories[ctx.index].lines
    end,
    delete_history = function()
      if #ctx.histories <= 0 then
        return
      end
      table.remove(ctx.histories, ctx.index)

      if ctx.index > #ctx.histories then
        ctx.index = #ctx.histories
      end
    end,
    render_counter = function()
      return ctx.enabled and "(" .. ctx.index .. "/" .. #ctx.histories .. ")" or ""
    end,
  }

  local m = setmetatable({}, {
    __index = function(_, key)
      if key == "bufnr" then
        return viewer_bufnr
      end
    end,
  })

  local init = function()
    local bind = function(fn)
      return function()
        if ctx.enabled then
          fn()
        end
      end
    end

    if viewer_bufnr == nil then
      viewer_bufnr = vim.api.nvim_create_buf(false, true)
      M.buffer_keymappings(viewer_bufnr, {
        next_history = bind(m.next_history),
        previous_history = bind(m.previous_history),
        delete_history = bind(m.delete_history),
      })
      vim.api.nvim_set_option_value("filetype", "json", { buf = viewer_bufnr })
    end
  end

  m.set_winbar = function(winnr)
    _winnr = winnr
    if _winnr and vim.api.nvim_win_is_valid(_winnr) then
      vim.api.nvim_set_option_value(
        "winbar",
        "%#Special#[Query Result" .. ctx.api.render_counter() .. "]%*",
        { win = _winnr }
      )
    end
  end

  local set_viewer_buf = function(lines)
    utils.set_buf_lines(viewer_bufnr, lines)
    m.set_winbar(_winnr)
  end

  m.set_query_result = function(jsonstr)
    local lines = ctx.enabled and (ctx.api.push_history(jsonstr) or ctx.api.get_history()) or utils.split_json(jsonstr)
    set_viewer_buf(lines)
  end

  m.previous_history = function()
    ctx.api.previous_history()
    set_viewer_buf(ctx.api.get_history())
  end

  m.next_history = function()
    ctx.api.next_history()
    set_viewer_buf(ctx.api.get_history())
  end

  m.delete_history = function()
    ctx.api.delete_history()
    set_viewer_buf(ctx.api.get_history())
  end

  init()

  return m
end

return M
