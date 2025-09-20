local M = {}

M.generate_uuid = function()
  local random = math.random
  local template = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"
  return string.gsub(template, "[xy]", function(c)
    local v = (c == "x") and random(0, 0xf) or random(8, 0xb)
    return string.format("%x", v)
  end)
end

M.switch_win_to_buf = function(bufnr)
  local win = vim.fn.win_findbuf(bufnr)
  local winnr
  if #win > 0 then
    winnr = win[1]
  else
    winnr = vim.api.nvim_get_current_win()
  end

  vim.api.nvim_win_set_buf(winnr, bufnr)
  vim.api.nvim_set_current_win(winnr)
end

return M
