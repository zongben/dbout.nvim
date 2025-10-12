# Dbout.nvim

**dbout.nvim** is a Neovim plugin that helps you connect to databases, execute SQL queries, and display the results in **JSON format**. 
No need to switch to external tools — everything happens inside Neovim, making your workflow faster and smoother.

<img width="2543" height="1393" alt="圖片" src="https://github.com/user-attachments/assets/d7d884bd-22d4-49e6-b8d5-22402bd707b1" />

https://github.com/user-attachments/assets/21d4295a-897b-422a-aa69-2d6cde4e555d

## Key Features

- **JSON Result Display**: View query results in a structured JSON format for easy reading and further processing.
- **No More Connection Strings In Your Neovim Config**: All your database connections are securely saved locally on your machine.
- **LSP Support**: Use `sqls` as the SQL language server, and spins up separate LSP instances per database connection to avoid mixing completions across different databases.

## Supported Databases

- SQLite
- PostgreSQL
- MySQL
- MSSQL

## Installation

Requirements:

- [Nodejs](https://github.com/nodejs/node)
- [sqls](https://github.com/sqls-server/sqls)

`sqls` is recommended to be installed via [mason.nvim](https://github.com/mason-org/mason.nvim). If you are not using mason, make sure sqls is installed and available in your system PATH.

With lazy.nvim:

```lua
{
  "zongben/dbout.nvim",
  build = "npm install",
  lazy = "VeryLazy",
  cmd = { "Dbout" },
  config = function()
    require("dbout").setup({})
  end,
}
```

## Configuration

The default configuration is as follows:

```lua
{
  keymaps = {
    queryer = {
      query = "<F5>",
      format = "<F11>",
      open_inspector = "<F12>",
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
```

## Usage

Use the following commands for database connection management:

`:Dbout OpenConnection` - Open a new buffer and connect to selected database connection  
`:Dbout NewConnection` - Create a new database connection  
`:Dbout DeleteConnection` - Delete an existing connection  
`:Dbout EditConnection` - Edit an existing connection  
`:Dbout AttachConnection` - Attach to selected connection in the current buffer (this is very useful after opening a .sql file)  

After opening or attaching a connection, a buffer for that database connection is created, named Queryer.  
Inside the Queryer buffer:

`F5` - Execute the current SQL query  
`F11` - Format SQL  
`F12` - Open Inspector  

The Inspector is a buffer used for inspecting database objects.  
Within the Inspector buffer:

`H` and `L` - Switch between tabs  
`I` - Inspect more details, such as table columns, triggers, views, etc.  

### Telescope Extension

For users with Telescope installed, you can load the dbout extension for easier database connection management:

```lua
require("telescope").load_extension("dbout")

--default config
require("telescope").setup({
  extensions = {
    dbout = {
      keymaps = {
        open_connection = "<cr>",
        new_connection = "n",
        delete_connection = "d",
        edit_connection = "e",
        attach_connection = "a",
      },
    },
  },
})
```

Then, you can open the database connection picker by calling `:Telescope dbout` or `require("telescope").extensions.dbout.dbout()`

### Snacks Sources

For users with Snacks installed, dbout automatically registers its sources.
You can open the database connection manager simply by calling `:Dbout`

```lua
--default config
require("dbout.snacks").setup({
  keymaps = {
    open_connection = "<cr>",
    new_connection = "n",
    delete_connection = "d",
    edit_connection = "e",
    attach_connection = "a",
  },
})

-- You can also configure the source:
Snacks.picker.sources.dbout = {
  -- your options here
  -- For more details, see:
  -- https://github.com/folke/snacks.nvim/blob/main/docs/picker.md
}
```

## NOTES

When opening a connection, you might see an **Sqls connection error**. 
However, based on my tests, Sqls is actually connecting to the server successfully. 
This error message seems to be an issue with Sqls itself. For now, I’m not sure how to disable it, so I suggest simply ignoring this error message.

--

If you’re using [mason-lspconfig](https://github.com/mason-org/mason-lspconfig.nvim) to automatically start LSP servers, I recommend excluding sqls from it.
dbout will automatically start sqls for you.

```lua
require("mason-lspconfig").setup({
  automatic_enable = {
    exclude = {
      "sqls",
    },
  },
})
```

## TODO

- [ ] CSV output
- [ ] query history
- [ ] layout system
- [ ] better LSP and tree sitting support
- [ ] mongodb support
