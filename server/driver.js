import { MsSql } from "./db/mssql.js";
import { MySql } from "./db/mysql.js";
import { Postgres } from "./db/postgres.js";
import { Sqlite } from "./db/sqlite.js";

const DB_TYPE = {
  MSSQL: "mssql",
  SQLITE: "sqlite3",
  POSTGRES: "postgresql",
  MYSQL: "mysql",
};

const DB_MAP = {
  [DB_TYPE.MSSQL]: MsSql,
  [DB_TYPE.SQLITE]: Sqlite,
  [DB_TYPE.POSTGRES]: Postgres,
  [DB_TYPE.MYSQL]: MySql,
};

class Driver {
  #connections = new Map();

  async createConnection(id, db_type, conn_str) {
    if (this.#connections.has(id)) {
      return "connected";
    }

    const db = DB_MAP[db_type];
    if (!db) {
      throw new Error(`${db_type} is not supported`);
    }

    const conn = await db.createConnection(conn_str);
    this.#connections.set(id, conn);
    return "connected";
  }

  async query(id, sql) {
    const conn = this.#connections.get(id);
    return await conn.query(sql);
  }

  async getTableList(id) {
    const conn = this.#connections.get(id);
    return await conn.getTableList();
  }

  async getViewList(id) {
    const conn = this.#connections.get(id);
    return await conn.getViewList();
  }

  async getStoreProcedureList(id) {
    const conn = this.#connections.get(id);
    return await conn.getStoreProcedureList();
  }

  async getFunctionList(id) {
    const conn = this.#connections.get(id);
    return await conn.getFunctionList();
  }
}

export const driver = new Driver();
