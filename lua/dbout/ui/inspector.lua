local utils = require("dbout.utils")

local inspector_bufnr

local tabs = {
  {
    display = "Tables",
    active = true,
  },
  {
    display = "Views",
    active = false,
  },
  {
    display = "StoreProcedures",
    active = false,
  },
  {
    display = "Functions",
    active = false,
  },
  {
    display = "Triggers",
    active = false,
  },
}

local set_winbar = function(winnr)
  local bar = {}
  for _, tab in ipairs(tabs) do
    if tab.active then
      table.insert(bar, "%#Title#[" .. tab.display .. "]%*")
    else
      table.insert(bar, tab.display)
    end
  end
  vim.api.nvim_set_option_value("winbar", table.concat(bar, "|"), { win = winnr })
end

local M = {}

M.buffer_keymappings = nil

M.open_inspector = function()
  if inspector_bufnr == nil then
    inspector_bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_option_value("filetype", "json", { buf = inspector_bufnr })
    M.buffer_keymappings(inspector_bufnr)
  end

  local winnr = utils.get_buf_win(inspector_bufnr)
  if not winnr then
    winnr = utils.create_right_win()
  end
  vim.api.nvim_win_set_buf(winnr, inspector_bufnr)
  set_winbar(winnr)
end

M.close_inspector = function()
  utils.close_buf_win(inspector_bufnr)
end

return M
