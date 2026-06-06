local M = {}

M.generate_uuid = function()
  local random = math.random
  local template = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"
  return string.gsub(template, "[xy]", function(c)
    local v = (c == "x") and random(0, 0xf) or random(8, 0xb)
    return string.format("%x", v)
  end)
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

M.split_json = function(jsonstr)
  return vim.split(jsonstr, "\n", { plain = true })
end

M.set_buf_lines = function(buf, lines)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
end

M.get_current_win_bufs = function()
  local wins = vim.api.nvim_tabpage_list_wins(0)
  local bufs = {}

  for _, winnr in ipairs(wins) do
    local bufnr = vim.api.nvim_win_get_buf(winnr)
    local buftype = vim.api.nvim_get_option_value("buftype", { buf = bufnr })
    if buftype ~= "nofile" then
      table.insert(bufs, bufnr)
    end
  end

  return bufs
end

return M
