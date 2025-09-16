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
    return await this.#pool.request().query(sql);
  }

  async getDbList() {
    const result = await this.query("SELECT name FROM sys.databases;");
    return result;
  }

  async getTableList(table_name) {
    const sql = `USE ${table_name}; SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE'`;
    return await this.query(sql);
  }
}
