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

M.close_buf_win = function(bufnr)
  if bufnr and vim.api.nvim_buf_is_loaded(bufnr) then
    local wins = vim.fn.win_findbuf(bufnr)
    if #wins > 0 then
      vim.api.nvim_win_close(wins[1], true)
    end
  end
end

M.get_buf_win = function(bufnr)
  local wins = vim.fn.win_findbuf(bufnr)
  if #wins == 0 then
    return nil
  end
  return wins[1]
end

M.create_right_win = function()
  vim.cmd("botright vsplit")
  return vim.api.nvim_get_current_win()
end

M.get_or_create_buf_win = function(bufnr)
  local winnr = M.get_buf_win(bufnr)
  if not winnr then
    winnr = M.create_right_win()
  end
  return winnr
end

M.split_json = function(jsonstr)
  return vim.split(jsonstr, "\n", { plain = true })
end

M.set_buf_lines = function(buf, lines)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
end

return M
