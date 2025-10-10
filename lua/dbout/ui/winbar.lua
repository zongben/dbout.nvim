local tab_switch = 1
local tab_state = {
  { index = 1, tabs = {
    "Tables",
    "Views",
    "StoreProcedures",
    "Functions",
  } },
  { index = 1, tabs = {
    "Columns",
    "Triggers",
  } },
}
local sub_tab_table_name

local set_top_winbar = function(winnr)
  local state = tab_state[1]
  local tab_index = state.index
  local tabs = state.tabs

  local bar = {}
  for index, tab in ipairs(tabs) do
    if index == tab_index then
      table.insert(bar, "%#Title#[" .. tab .. "]%*")
    else
      table.insert(bar, tab)
    end
  end
  vim.api.nvim_set_option_value("winbar", table.concat(bar, "|"), { win = winnr })
  vim.api.nvim_win_set_cursor(winnr, { 1, 0 })
end

local set_sub_winbar = function(winnr)
  local state = tab_state[2]

  local bar = {}
  table.insert(bar, "<--Back")
  table.insert(bar, " %#Directory#" .. sub_tab_table_name .. "%* ")

  for index, tab in ipairs(state.tabs) do
    if index == state.index then
      table.insert(bar, "%#Title#[" .. tab .. "]%*")
    else
      table.insert(bar, tab)
    end
  end

  vim.api.nvim_set_option_value("winbar", table.concat(bar, "|"), { win = winnr })
  vim.api.nvim_win_set_cursor(winnr, { 1, 0 })
end

local M = {}

M.set_sub_tab_table = function(table_name)
  sub_tab_table_name = table_name
end

M.get_sub_tab_table = function()
  return sub_tab_table_name
end

M.set_winbar = function(winnr)
  if tab_switch == 1 then
    set_top_winbar(winnr)
  elseif tab_switch == 2 then
    set_sub_winbar(winnr)
  end
end

M.tab_switch = function(tabnr)
  tab_switch = tabnr
end

M.next_tab = function()
  local state = tab_state[tab_switch]
  state.index = state.index + 1
  if state.index > #state.tabs then
    state.index = 1
  end
end

M.previous_tab = function()
  local state = tab_state[tab_switch]
  state.index = state.index - 1
  if state.index < 1 then
    state.index = #state.tabs
  end
end

M.get_current_tab = function()
  local state = tab_state[tab_switch]
  local tab = state.tabs[state.index]
  return tab
end

M.reset = function()
  M.tab_switch(1)
  tab_state[1].index = 1
  tab_state[2].index = 1
end

M.back = function()
  M.tab_switch(1)
  tab_state[2].index = 1
end

return M
