# Dbout.nvim

**dbout.nvim** is a Neovim plugin that helps you connect to databases, execute SQL queries, and display the results in **JSON format**. 
No need to switch to external tools. Everything happens inside Neovim, making your workflow faster and smoother.

<img width="2543" height="1393" alt="圖片" src="https://github.com/user-attachments/assets/d7d884bd-22d4-49e6-b8d5-22402bd707b1" />

https://github.com/user-attachments/assets/21d4295a-897b-422a-aa69-2d6cde4e555d

## Key Features

- **JSON Result Display**: View query results in a structured JSON format for easy reading and native highlighting.
- **No More Connection Strings In Your Neovim Config**: All your database connections are securely saved locally on your machine.
- **Buffer-Isolated Connections**: Every database query buffer maintains its own isolated connection state.

## Supported Databases

- SQLite
- PostgreSQL
- MySQL
- MSSQL
- MongoDB

## Installation

Requirements:

- [Nodejs](https://github.com/nodejs/node)

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
  ui = {
    -- See layout configuration section.
    layout = {
      inspector = 1,
      viewer = 3,
    },
    -- Open utility panels by default when a buffer attaches to a connection.
    init_open = {
      inspector = true,
      viewer = true,
    },
  },
  viewer = {
    history = {
      enabled = true,
      limit = 10,
    },
  },
  -- Set empty string to disable keymap.
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
    viewer = {
      next_history = "}",
      previous_history = "{",
      delete_history = "<c-x>",
    },
  },
  -- Called when a queryer buffer attaches to a connection.
  -- Use this to configure your preferred LSP.
  -- This function provides connection details to help set up the LSP.
  on_attach = function(conn, bufnr)
    -- conn is a table
    -- {
    --   name, db_type, host, port, user, password, database, connstr
    -- }
  end
}
```

### Layout Configuration

The layout coordinates positions using a 3-column system (`1` = Left, `2` = Middle/Relative, `3` = Right).

```text
Position:        1               2               3
         +---------------+---------------+---------------+
         |               |               |               |
         |     LEFT      |   RELATIVE    |     RIGHT     |
         |               |               |               |
         +---------------+---------------+---------------+
```

- If both the viewer and inspector are set to `1`, the newer panel opens on the left.
- If both are set to `3`, vice versa (the newer opens on the right).
- However, both panels cannot be set to `2` simultaneously.

## Usage

Use the following commands for database connection management:

`:Dbout OpenConnection` - Open a new buffer and connect to selected database connection  
`:Dbout NewConnection` - Create a new database connection  
`:Dbout DeleteConnection` - Delete an existing connection  
`:Dbout EditConnection` - Edit an existing connection  
`:Dbout AttachConnection` - Attach to selected connection in the current buffer (this is very useful after opening a .sql file)  

After opening or attaching a connection, a buffer for that database connection is created, named Queryer.  
Inside the Queryer buffer:

`F2` - Format SQL  
`F5` - Execute the current SQL query and open viewer with query result  

The Inspector is a buffer used for inspecting database objects.  
Within the Inspector buffer:

`H` and `L` - Switch between tabs  
`I` - Inspect more details, such as table columns, triggers, views, etc.  
`R` - Refresh inspector for clear caches.  

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

## MongoDB

Since MongoDB cannot be queried using script-like SQL syntax, dbout.nvim utilizes **Extended JSON (EJSON)** for data queries, unlike `mongosh`, which uses short API helper methods.  

Below is an example of an EJSON query.

```json
{
  "find": "users",
  "filter": {
    "status": "active",
    "createdAt": {
      "$gte": {
        "$date": "2026-01-01T00:00:00Z"
      }
    }
  },
  "projection": {
    "name": 1,
    "email": 1
  },
  "sort": {
    "createdAt": -1
  },
  "limit": 10
}
```

For more details on the syntax and capabilities,
please refer to the official [MongoDB Extended JSON documentation](https://www.mongodb.com/docs/manual/reference/mongodb-extended-json/).

## TODO

- [x] layout system
- [x] inspector cache
- [x] query history
- [x] mongodb support
- [ ] queryer fork
- [ ] CSV output
