import { MsSql } from "./db/mssql.js";

const DB_TYPE = {
  MSSQL: "mssql",
};

class Driver {
  #connections = new Map();

  async createConnection(id, db_type, conn_str) {
    switch (db_type) {
      case DB_TYPE.MSSQL: {
        const conn = await MsSql.createConnection(conn_str);
        this.#connections.set(id, conn);
        return "";
      }
      default: {
        throw new Error(`${db_type} is not supported`);
      }
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

  async getTableList(id, db_name) {
    const conn = this.#connections.get(id);
    return await conn.getTableList(db_name);
  }
}

export const driver = new Driver();
