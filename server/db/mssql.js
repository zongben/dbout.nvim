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
    const result = await this.#pool.request().query(sql);
    return {
      total: result.rowsAffected[0],
      rows: result.recordset ?? [],
    };
  }

  async getTableList() {
    const sql = `SELECT TABLE_NAME as name FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE'`;
    return await this.query(sql);
  }
}
