local M = {}

M.defaults = {
  enable_telescope = true,
  keymap = {
    telescope = {
      new_connection = "n",
      delete_connection = "d",
      edit_connection = "e",
      conn_connection = "c",
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
