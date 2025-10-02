# Dbout.nvim

**dbout.nvim** is a Neovim plugin that helps you connect to databases, execute SQL queries, and display the results in **JSON format**. 
No need to switch to external tools — everything happens inside Neovim, making your workflow faster and smoother.

https://github.com/user-attachments/assets/88241a1c-b718-4595-b9be-4f53fdba197a

## Key Features

* JSON Result Display: View query results in a structured JSON format for easy reading and further processing.
* No More Connection Strings In Your Neovim Config: All your database connections are securely saved locally on your machine.
* LSP Support: Use `sqls` as the SQL language server, and spins up separate LSP instances per database connection to avoid mixing completions across different databases.
* Quick Database Connections: Easily manage multiple database connections with telescope.
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
  }
}
```

## Usage

Call `Dbout` to open the database connection manager:  

`n` – Create a new database connection  
`d` – Delete an existing connection  
`e` – Edit an existing connection  

After selecting a connection, a buffer for that database connection will be opened.  
Inside the connection buffer:  

`F5` – Execute the current SQL query  
`F12` – List all tables in the database  
