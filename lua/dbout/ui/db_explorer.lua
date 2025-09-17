local supported_db = { "mssql", "sqlite" }

local M = {}

M.set_keymaps = function(ui, buf)
  local map = function(mode, key, cb)
    vim.keymap.set(mode, key, cb, { buffer = buf })
  end

  map("n", "n", function()
    vim.ui.select(supported_db, {
      prompt = "choose a database",
    }, function(item)
      if not item then
        return
      end

      vim.notify("you choose " .. item)
    end)
  end)

  map("n", "q", function()
    ui.close_db_explorer()
  end)
end

return M
