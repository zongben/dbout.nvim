local M = {}

M.defaults = {
  enable_telescope = true,
  keymap = {
    telescope = {
      new_connection = "n",
      delete_connection = "d",
      edit_connection = "e",
      attach_connection = "a",
    },
    queryer = {
      query = "<F5>",
      inspect = "<F12>",
    },
    viewer = {
      close = "q",
    },
    inspector = {
      close = "q",
    },
  },
}

return M
