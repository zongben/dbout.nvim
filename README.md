# Dbout.nvim

**dbout.nvim** is a Neovim plugin that helps you connect to databases, execute SQL queries, and display the results in **JSON format**. 
No need to switch to external tools — everything happens inside Neovim, making your workflow faster and smoother.

https://github.com/user-attachments/assets/88241a1c-b718-4595-b9be-4f53fdba197a

## Key Features

* JSON Result Display: View query results in a structured JSON format for easy reading and further processing.
* No More Connection Strings In Your Neovim Config: All your database connections are securely saved locally on your machine.
* LSP Support: Use `sqls` as the SQL language server, and spins up separate LSP instances per database connection to avoid mixing completions across different databases.
* Cross-Database Support: Unified interface for different databases.
* Execute SQL Queries: Run SQL statements directly within Neovim.

## Supported Databases

* SQLite
* PostgreSQL
* MySQL
* MSSQL

## Installation

Requirements:

* [Nodejs](https://github.com/nodejs/node)
* [jq](https://github.com/jqlang/jq)
* [sqls](https://github.com/sqls-server/sqls)

`sqls` is recommended to be installed via [mason.nvim](https://github.com/mason-org/mason.nvim). If you are not using mason, make sure sqls is installed and available in your system PATH.

With lazy.nvim:

```lua
{
  "zongben/dbout.nvim",
  build = "npm install",
  --this is optional if you disable telescope
  dependencies = {
    "nvim-telescope/telescope.nvim",
    "nvim-lua/plenary.nvim"
  },
  config = function()
    require("dbout").setup({})
  end,
}
```

## Configuration

The default configuration is as follows:

```lua
{
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
  }
}
```

## Usage

For users with Telescope, you can call `:Dbout` to open the database connection manager:

`<CR>` - Open a new buffer and connect to selected database connection
`n` – Create a new database connection  
`d` – Delete an existing connection  
`e` – Edit an existing connection  
`a` – Attach to selected connection in the current buffer (this is very useful after opening a .sql file)

Alternatively, you can use user commands to perform the same actions:

`:Dbout OpenConnection`  
`:Dbout NewConnection`  
`:Dbout DeleteConnection`  
`:Dbout EditConnection`  
`:Dbout AttachConnection`  

After open/attach a connection, a buffer for that database connection will be connected.  
Inside the connection buffer:  

`F5` – Execute the current SQL query  
`F12` – List all tables in the database  
