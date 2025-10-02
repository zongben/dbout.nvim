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
      table_list = "<F12>",
    },
    viewer = {
      close = "q",
    },
  },
}

return M
