import { MsSql } from "./db/mssql.js";

/**
 * @enum {string}
 */
const DB_TYPE = {
  MSSQL: "mssql",
};

class Driver {
  /**
   * @type{Map<string, Database>}
   */
  #connections = new Map();

  /**
   * @param {string} id
   * @param {DB_TYPE} db_type
   * @param {string} conn_str
   */
  async createConnection(id, db_type, conn_str) {
    switch (db_type) {
      case DB_TYPE.MSSQL: {
        const conn = await MsSql.createConnection(conn_str);
        this.#connections.set(id, conn);
        return "connected";
      }
      default: {
        throw new Error(`${db_type} is not supported`);
      }
    }
  }

  /**
   * @param {string} id
   */
  async getDbList(id) {
    const conn = this.#connections.get(id);
    return await conn.getDbList();
  }

  /**
   * @param {string} id
   * @param {string} sql
   */
  async query(id, sql) {
    const conn = this.#connections.get(id);
    return await conn.query(sql);
  }

  /**
   * @param {string} id
   * @param {string} db_name
   */
  async getTableList(id, db_name) {
    const conn = this.#connections.get(id);
    return await conn.getTableList(db_name);
  }

  /**
   * @param {string} id
   * @param {string} db_name
   */
  async tryQueryDb(id, db_name) {
    const conn = this.#connections.get(id);
    await conn.tryQueryDb(db_name);
    return "successed";
  }
}

export const driver = new Driver();
