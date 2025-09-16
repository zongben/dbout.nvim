import { MsSql } from "./db/mssql.js";

/**
 * @readonly
 * @enum {string}
 */
export const DB_TYPE = {
  MSSQL: "MSSQL",
};

class Driver {
  #connections = new Map();

  /**
   * @param {string} id
   * @param {DB_TYPE} db_type
   * @param {string} conn_str
   */
  async createConnection(id, db_type, conn_str) {
    switch (db_type) {
      case "MSSQL":
        const conn = await MsSql.createConnection(conn_str);
        this.#connections.set(id, conn);
        break;
      default:
        throw new Error(`${db_type} is not supported`);
    }
  }

  async getDbList(id) {
    const conn = this.#connections.get(id);
    return await conn.getDbList();
  }

  async query(id, sql) {
    const conn = this.#connections.get(id);
    return await conn.query(sql);
  }

  async getTableList(id, table_name) {
    const conn = this.#connections.get(id);
    return await conn.getTableList(table_name);
  }
}

export const driver = new Driver();
