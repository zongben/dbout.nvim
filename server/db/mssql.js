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
}
