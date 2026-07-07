import { Mongodb } from "./db/mongodb.js";
import { MsSql } from "./db/mssql.js";
import { MySql } from "./db/mysql.js";
import { Postgres } from "./db/postgres.js";
import { Sqlite } from "./db/sqlite.js";

const DB_TYPE = {
  MSSQL: "mssql",
  SQLITE: "sqlite3",
  POSTGRES: "postgresql",
  MYSQL: "mysql",
  MONGODB: "mongodb",
};

const DB_MAP = {
  [DB_TYPE.MSSQL]: MsSql,
  [DB_TYPE.SQLITE]: Sqlite,
  [DB_TYPE.POSTGRES]: Postgres,
  [DB_TYPE.MYSQL]: MySql,
  [DB_TYPE.MONGODB]: Mongodb,
};

export const makeDriver = () => {
  const connections = new Map();

  return {
    createConnection: async (id, db_type, conn_str) => {
      if (connections.has(id)) {
        return "connected";
      }

      const db = DB_MAP[db_type];
      if (!db) {
        throw new Error(`${db_type} is not supported`);
      }

      const conn = await db.makeConnection(conn_str);
      connections.set(id, conn);
      return "connected";
    },
    closeConnection: async (id) => {
      const conn = connections.get(id);
      if (conn) {
        await conn.close();
      }
      connections.delete(id);
    },
    getConnectionInfo: async (id) => {
      const conn = connections.get(id);
      return await conn.getConnectionInfo();
    },
    query: async (id, sql) => {
      const conn = connections.get(id);
      return await conn.query(sql);
    },
    getTableList: async (id) => {
      const conn = connections.get(id);
      return await conn.getTableList();
    },
    getViewList: async (id) => {
      const conn = connections.get(id);
      return await conn.getViewList();
    },
    getStoreProcedureList: async (id) => {
      const conn = connections.get(id);
      return await conn.getStoreProcedureList();
    },
    getFunctionList: async (id) => {
      const conn = connections.get(id);
      return await conn.getFunctionList();
    },
    getView: async (id, view_name) => {
      const conn = connections.get(id);
      return await conn.getView(view_name);
    },
    getStoreProcedure: async (id, procedure_name) => {
      const conn = connections.get(id);
      return await conn.getStoreProcedure(procedure_name);
    },
    getFunction: async (id, function_name) => {
      const conn = connections.get(id);
      return await conn.getFunction(function_name);
    },
    getTable: async (id, table_name) => {
      const conn = connections.get(id);
      return await conn.getTable(table_name);
    },
    getTrigger: async (id, trig_name) => {
      const conn = connections.get(id);
      return await conn.getTrigger(trig_name);
    },
    getTriggerList: async (id, table_name) => {
      const conn = connections.get(id);
      return await conn.getTriggerList(table_name);
    },
    generateSelectSQL: async (id, table_name) => {
      const conn = connections.get(id);
      const table = await conn.getTable(table_name);
      const columns = table.rows.map((col) => {
        return col.column_name;
      });
      const pkey = table.rows
        .filter((col) => col.is_pk)
        .map((col) => {
          return `${col.column_name} = @${col.column_name}`;
        });

      const sql = `SELECT ${columns.join(",")} FROM ${table_name} WHERE ${pkey.join(" AND ")}`;
      return conn.format(sql);
    },
    generateUpdateSQL: async (id, table_name) => {
      const conn = connections.get(id);
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

      const sql = `UPDATE ${table_name} SET ${columns.join(",")} WHERE ${pkey.join(" AND ")}`;
      return conn.format(sql);
    },
    generateInsertSQL: async (id, table_name) => {
      const conn = connections.get(id);
      const table = await conn.getTable(table_name);
      const columns = table.rows.map((col) => {
        return col.column_name;
      });
      const values = table.rows.map((col) => {
        return `@${col.column_name}`;
      });

      const sql = `INSERT INTO ${table_name}(${columns.join(",")}) VALUES (${values.join(",")})`;
      return conn.format(sql);
    },
    format: async (id, sql) => {
      const conn = connections.get(id);
      return conn.format(sql);
    },
  };
};
