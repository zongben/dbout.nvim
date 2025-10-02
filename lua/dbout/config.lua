local M = {}

M.defaults = {
  keymap = {
    telescope = {
      new_connection = "n",
      delete_connection = "d",
      edit_connection = "e",
    },
    queryer = {
      query = "<F5>",
    },
    viewer = {
      close = "q",
    },
  },
}

return M
