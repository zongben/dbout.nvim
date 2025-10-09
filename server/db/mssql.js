import sql from "mssql";

export class MsSql {
  #pool;

  async #init(config) {
    this.#pool = await new sql.ConnectionPool(config).connect();
  }

  static async createConnection(conn_str) {
    const config = sql.ConnectionPool.parseConnectionString(conn_str);
    const instance = new MsSql();
    await instance.#init(config);
    return instance;
  }

  async query(sql) {
    const start = Date.now();
    const result = await this.#pool.request().query(sql);
    const end = Date.now();

    return {
      duration: `${end - start}ms`,
      total: result.rowsAffected[0],
      rows: result.recordset ?? [],
    };
  }

  async getTableList() {
    const sql = `
      SELECT TABLE_NAME as table_name 
      FROM INFORMATION_SCHEMA.TABLES 
      WHERE TABLE_TYPE = 'BASE TABLE' 
      ORDER BY TABLE_NAME
    `;
    return await this.query(sql);
  }

  async getViewList() {
    const sql = `
      SELECT TABLE_NAME as view_name 
      FROM INFORMATION_SCHEMA.TABLES 
      WHERE TABLE_TYPE = 'VIEW' 
      ORDER BY TABLE_NAME
    `;
    return await this.query(sql);
  }

  async getStoreProcedureList() {
    const sql = `
      SELECT 
        ROUTINE_SCHEMA as schema_name,
        ROUTINE_NAME as procedure_name
      FROM INFORMATION_SCHEMA.ROUTINES
      WHERE ROUTINE_TYPE = 'PROCEDURE'
      ORDER BY ROUTINE_SCHEMA, ROUTINE_NAME;
    `;
    return await this.query(sql);
  }

  async getFunctionList() {
    const sql = `
      SELECT 
        ROUTINE_SCHEMA as schema_name,
        ROUTINE_NAME as function_name
      FROM INFORMATION_SCHEMA.ROUTINES
      WHERE ROUTINE_TYPE = 'FUNCTION'
      ORDER BY ROUTINE_SCHEMA, ROUTINE_NAME;
    `;
    return await this.query(sql);
  }

  async getView(view_name) {
    const sql = `
      SELECT VIEW_DEFINITION as 'definition'
      FROM INFORMATION_SCHEMA.VIEWS
      WHERE TABLE_NAME = '${view_name}'
    `;
    return await this.query(sql);
  }

  async getStoreProcedure(procedure_name) {
    const sql = `
      SELECT 
        m.definition AS definition
      FROM sys.procedures p
      INNER JOIN sys.sql_modules m ON p.object_id = m.object_id
      WHERE p.name = '${procedure_name}';
    `;
    return await this.query(sql);
  }

  async getFunction(function_name) {
    const sql = `
      SELECT 
        m.definition
      FROM sys.objects o
      JOIN sys.sql_modules m ON o.object_id = m.object_id
      JOIN sys.schemas s ON o.schema_id = s.schema_id
      WHERE o.type IN ('FN', 'IF', 'TF')
        AND o.name = '${function_name}';
    `;
    return await this.query(sql);
  }

  async getTable(table_name) {
    const sql = `
      SELECT 
        c.column_id AS column_id,
        c.name AS column_name,
        t.name AS data_type,
        c.max_length AS max_length,
        c.is_nullable AS is_nullable,
        dc.definition AS default_value,
        MAX(CAST(CASE WHEN i.is_primary_key = 1 THEN 1 ELSE 0 END AS int)) AS is_pk,
        MAX(CAST(CASE WHEN i.is_unique = 1 THEN 1 ELSE 0 END AS int)) AS is_unique
      FROM sys.columns c
      LEFT JOIN sys.types t 
        ON t.system_type_id = c.system_type_id 
        AND t.user_type_id = t.system_type_id
      LEFT JOIN sys.default_constraints dc 
        ON dc.object_id = c.default_object_id
      LEFT JOIN sys.index_columns ic 
        ON ic.object_id = c.object_id 
        AND c.column_id = ic.column_id
      LEFT JOIN sys.indexes i 
        ON i.object_id = c.object_id 
        AND i.index_id = ic.index_id
      WHERE OBJECT_NAME(c.object_id) = '${table_name}'
      GROUP BY c.column_id, c.name, t.name, c.max_length, c.is_nullable, dc.definition
      ORDER BY c.column_id;
    `;
    const result = await this.query(sql);
    result.rows = result.rows.map((item) => {
      return {
        column_name: item.column_name,
        data_type: item.data_type,
        max_length: item.max_length,
        is_nullable: item.is_nullable,
        default_value: item.default_value,
        is_pk: item.is_pk === 1 ? true : false,
        is_unique: item.is_unique === 1 ? true : false,
      };
    });
    return result;
  }

  async getTrigger(trig_name) {
    const sql = `
      SELECT m.definition
      FROM sys.sql_modules m
      JOIN sys.triggers t ON m.object_id = t.object_id
      WHERE t.name = '${trig_name}';
    `;
    return await this.query(sql);
  }

  async getTriggerList(table_name) {
    const sql = `
      SELECT t.name AS trigger_name
      FROM sys.triggers t
      WHERE t.parent_id = OBJECT_ID('${table_name}');
    `;
    return await this.query(sql);
  }
}
