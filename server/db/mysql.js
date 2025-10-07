import mysql from "mysql2/promise";

export class MySql {
  #pool;

  async #init(config) {
    this.#pool = mysql.createPool(config);
  }

  static async createConnection(conn_str) {
    const instance = new MySql();
    await instance.#init(conn_str);
    return instance;
  }

  async query(sql) {
    const start = Date.now();
    const [result, _] = await this.#pool.execute(sql);
    const end = Date.now();

    let total, rows;
    if (Array.isArray(result)) {
      rows = result;
      total = result.length;
    } else {
      rows = [];
      total = result.affectedRows;
    }
    return {
      duration: `${end - start}ms`,
      total,
      rows,
    };
  }

  async getTableList() {
    const sql = `
      SELECT TABLE_NAME as table_name
      FROM information_schema.tables
      WHERE table_schema = DATABASE()
      AND table_type = 'BASE TABLE'
      ORDER BY TABLE_NAME
    `;
    return await this.query(sql);
  }

  async getViewList() {
    const sql = `
      SELECT TABLE_NAME as view_name
      FROM information_schema.tables
      WHERE table_schema = DATABASE()
      AND table_type = 'VIEW'
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
        AND ROUTINE_SCHEMA = DATABASE()
      ORDER BY ROUTINE_NAME;
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
        AND ROUTINE_SCHEMA = DATABASE()
      ORDER BY ROUTINE_NAME;
    `;
    return await this.query(sql);
  }
}
