--- @meta

--- @class Connection
--- @field id string
--- @field name string
--- @field db_type string
--- @field connstr string

--- @class Compositor
--- @field queryer table<integer, Queryer>

--- @class Inspector
--- @field bufnr integer
--- @field open_inspector fun(conn: Connection, bufnr: integer): nil
--- @field set_winbar fun(winnr: integer): nil
--- @field close_inspector fun(): nil
--- @field next_tab fun(): nil
--- @field previous_tab fun(): nil
--- @field inspect fun(): nil
--- @field back fun(): nil
--- @field reset fun(): nil

--- @class Queryer
--- @field conn Connection
--- @field bufnr integer
--- @field inspector Inspector | nil
--- @field Viewer table | nil

--- @class Winbar
--- @field set_winbar fun(winnr: integer): nil
--- @field tab_switch fun(tabnr: integer): nil
--- @field next_tab fun(): nil
--- @field previous_tab fun(): nil
--- @field get_current_tab fun(): string
--- @field reset fun(): nil
--- @field back fun(): nil
--- @field set_sub_tab_table fun(table_name: string): nil
--- @field get_sub_tab_table fun(): string
