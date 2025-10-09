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

  async getView(id, view_name) {
    const conn = this.#connections.get(id);
    return await conn.getView(view_name);
  }

  async getStoreProcedure(id, procedure_name) {
    const conn = this.#connections.get(id);
    return await conn.getStoreProcedure(procedure_name);
  }

  async getFunction(id, function_name) {
    const conn = this.#connections.get(id);
    return await conn.getFunction(function_name);
  }

  async getTable(id, table_name) {
    const conn = this.#connections.get(id);
    return await conn.getTable(table_name);
  }

  async getTrigger(id, trig_name) {
    const conn = this.#connections.get(id);
    return await conn.getTrigger(trig_name);
  }

  async getTriggerList(id, table_name) {
    const conn = this.#connections.get(id);
    return await conn.getTriggerList(table_name);
  }

  async generateSelectSQL(id, table_name) {
    const conn = this.#connections.get(id);
    const table = await conn.getTable(table_name);
    const columns = table.rows.map((col) => {
      return col.column_name;
    });
    const pkey = table.rows
      .filter((col) => col.is_pk)
      .map((col) => {
        return `${col.column_name} = @${col.column_name}`;
      });

    const sql = `SELECT\n  ${columns.join(",\n  ")}\nFROM ${table_name}\nWHERE ${pkey.join(" AND ")}`;
    return sql;
  }

  async generateUpdateSQL(id, table_name) {
    const conn = this.#connections.get(id);
    const table = await conn.getTable(table_name);
    const columns = table.rows
      .filter((col) => !col.is_pk)
      .map((col) => {
        return `${col.column_name} = @${col.column_name}`;
      });
    const pkey = table.rows
      .filter((col) => col.is_pk)
      .map((col) => {
        return `${col.column_name} = @${col.column_name}`;
      });

    const sql = `UPDATE ${table_name} SET\n  ${columns.join(",\n  ")}\nWHERE ${pkey.join(" AND ")}`;
    return sql;
  }

  async generateInsertSQL(id, table_name) {
    const conn = this.#connections.get(id);
    const table = await conn.getTable(table_name);
    const columns = table.rows.map((col) => {
      return col.column_name;
    });
    const values = table.rows.map((col) => {
      return `@${col.column_name}`;
    });

    const sql = `INSERT INTO(\n  ${columns.join(",\n  ")}\n)\nVALUES (\n  ${values.join(",\n  ")}\n)`;
    return sql;
  }
}

export const driver = new Driver();
