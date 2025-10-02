# Dbout.nvim

**dbout.nvim** is a Neovim plugin that helps you connect to databases, execute SQL queries, and display the results in **JSON format**. 
No need to switch to external tools — everything happens inside Neovim, making your workflow faster and smoother.

## Key Features

* JSON Result Display: View query results in a structured JSON format for easy reading and further processing.
* No more connection strings in your neovim config: All your database connections are securely saved locally on your machine.
* Quick Database Connections: Easily manage multiple database connections with telescope.
* Cross-Database Support: Unified interface for different databases.
* Execute SQL Queries: Run SQL statements directly within Neovim.

## Supported Databases

* SQLite
* PostgreSQL
* MySQL
* MSSQL

## Installation

[node](https://github.com/nodejs/node) and [jq](https://github.com/jqlang/jq) is required.

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
