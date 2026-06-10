local M = {}

M.defaults = {
  ui = {
    layout = {
      inspector = 1,
      viewer = 3,
    },
    init_open = {
      inspector = true,
      viewer = true,
    },
  },
  keymaps = {
    global = {
      toggle_inspector = "<F12>",
      toggle_viewer = "<F11>",
      close = "q",
    },
    queryer = {
      query = "<F5>",
      format = "<F2>",
    },
    inspector = {
      next_tab = "L",
      previous_tab = "H",
      inspect = "I",
      back = "<BS>",
      refresh = "R",
    },
  },
  on_attach = nil,
}

return M
