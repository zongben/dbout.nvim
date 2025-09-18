import sql from "mssql";

export class MsSql {
  /** @type {sql.ConnectionPool} */
  #pool;

  constructor() {}

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
    return result.recordsets.map((rows) => ({
      total: rows.length,
      rows,
    }));
  }

  async getDbList() {
    const result = await this.query("SELECT name FROM sys.databases;");
    return result;
  }

  async getTableList(db_name) {
    const sql = `USE ${db_name}; SELECT TABLE_NAME as table_name FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE'`;
    return await this.query(sql);
  }
}
