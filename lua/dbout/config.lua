local M = {}

M.defaults = {
  ui = {
    layout = {
      inspector = 1,
      viewer = 3,
    },
  },
  keymaps = {
    global = {
      toggle_inspector = "<F12>",
      close = "q",
    },
    queryer = {
      query = "<F5>",
      format = "<F11>",
    },
    inspector = {
      next_tab = "L",
      previous_tab = "H",
      inspect = "I",
      back = "<BS>",
    },
  },
  on_attach = nil,
}

return M
