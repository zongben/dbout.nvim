local utils = require("dbout.utils")

local M = {}

M.buffer_keymappings = nil

M.new = function()
  local viewer_bufnr

  local m = setmetatable({}, {
    __index = function(_, key)
      if key == "bufnr" then
        return viewer_bufnr
      end
    end,
  })

  m.open_viewer = function()
    if viewer_bufnr == nil then
      viewer_bufnr = vim.api.nvim_create_buf(false, true)
      M.buffer_keymappings(viewer_bufnr, {
        close_viewer = m.close_viewer,
      })
    end
    vim.api.nvim_set_option_value("filetype", "json", { buf = viewer_bufnr })

    return viewer_bufnr
  end

  m.set_viewer = function(jsonstr)
    local lines = utils.split_json(jsonstr)
    utils.set_buf_lines(viewer_bufnr, lines)
  end

  m.close_viewer = function()
    utils.close_buf_win(viewer_bufnr)
  end

  m.set_winbar = function(winnr)
    if winnr and vim.api.nvim_win_is_valid(winnr) then
      vim.api.nvim_set_option_value("winbar", "%#Special#[Query Result]%*", { win = winnr })
    end
  end

  return m
end

return M
