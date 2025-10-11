local M = {}

M.defaults = {
  keymaps = {
    queryer = {
      query = "<F5>",
      open_inspector = "<F12>",
      format = "<F11>",
    },
    viewer = {
      close = "q",
    },
    inspector = {
      close = "q",
      next_tab = "L",
      previous_tab = "H",
      inspect = "I",
      back = "<BS>",
    },
  },
}

return M
