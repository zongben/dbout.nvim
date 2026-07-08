local M = {}

local function caps_tabs(tabs, capabilities)
  local result = {}

  for _, tab in ipairs(tabs) do
    if capabilities[tab] then
      table.insert(result, tab)
    end
  end

  return result
end

M.new = function(capabilities)
  local top_level_tabs = { "Tables", "Views", "StoreProcedures", "Functions" }
  local sub_tabs = { "Columns", "Triggers", "Indexes" }

  local current_layer = 1
  local layers = {
    {
      index = 1,
      tabs = caps_tabs(top_level_tabs, capabilities),
    },
    {
      index = 1,
      tabs = caps_tabs(sub_tabs, capabilities),
    },
  }
  local sub_tab_table_name = nil

  local render_tabs = function(layer_idx, prefix)
    local state = layers[layer_idx]
    local bar = prefix or {}

    for index, tab in ipairs(state.tabs) do
      if index == state.index then
        table.insert(bar, "%#Title#[" .. tab .. "]%*")
      else
        table.insert(bar, tab)
      end
    end

    return table.concat(bar, "|")
  end

  local reset_cursor = function(winnr)
    vim.api.nvim_win_set_cursor(winnr, { 1, 0 })
  end

  local m = {}

  m.set_sub_tab_table = function(table_name)
    sub_tab_table_name = table_name
  end

  m.get_sub_tab_table = function()
    return sub_tab_table_name
  end

  m.set_winbar = function(winnr)
    if not winnr or not vim.api.nvim_win_is_valid(winnr) then
      return
    end

    local winbar_str = ""
    if current_layer == 1 then
      winbar_str = render_tabs(1)
    elseif current_layer == 2 then
      local prefix = {
        " ◀ Back ",
        " %#Title#" .. sub_tab_table_name .. "%* ",
      }
      winbar_str = render_tabs(2, prefix)
    end

    vim.api.nvim_set_option_value("winbar", winbar_str, { win = winnr })
    reset_cursor(winnr)
  end

  m.tab_switch = function(layer_idx)
    if layers[layer_idx] then
      current_layer = layer_idx
    end
  end

  m.next_tab = function()
    local state = layers[current_layer]
    state.index = (state.index % #state.tabs) + 1
  end

  m.previous_tab = function()
    local state = layers[current_layer]
    state.index = (state.index - 2 + #state.tabs) % #state.tabs + 1
  end

  m.get_current_tab = function()
    local state = layers[current_layer]
    return state.tabs[state.index]
  end

  m.reset = function()
    current_layer = 1
    layers[1].index = 1
    layers[2].index = 1
  end

  m.back = function()
    current_layer = 1
    layers[2].index = 1
  end

  return m
end

return M
