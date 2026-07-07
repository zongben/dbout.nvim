import { MongoClient } from "mongodb";
import { EJSON } from "bson";

const makeMongodb = async (conn_str) => {
  const url = new URL(conn_str);

  const client = new MongoClient(conn_str);
  await client.connect();
  const db = client.db(url.pathname.replace(/^\//, ""));

  const instance = {
    getConnectionInfo: () => {
      return {
        host: url.hostname,
        port: Number(url.port) || 27017,
        user: decodeURIComponent(url.username),
        password: decodeURIComponent(url.password),
        database: url.pathname.replace(/^\//, ""),
      };
    },
    close: async () => {
      await client.close();
    },
    format: (ejson) => {
      return EJSON.stringify(EJSON.parse(ejson), null, 2);
    },
    query: async (ejson) => {
      const cmd = EJSON.parse(ejson);

      const start = Date.now();
      const result = await db.command(cmd);
      const end = Date.now();

      const rows = result.cursor?.firstBatch ?? result;

      return {
        duration: `${end - start}ms`,
        total: Array.isArray(rows) ? rows.length : 0,
        rows,
      };
    },
    getTableList: async () => {
      const cmd = `
        {
          "listCollections": 1,
          "filter": { "type": "collection" }
        }
      `;
      const result = await instance.query(cmd);
      result.rows = result.rows.map((row) => {
        return {
          table_name: row.name,
        };
      });
      return result;
    },
    getViewList: async () => {
      return "Not Supported";
    },
    getStoreProcedureList: async () => {
      return "Not Supported";
    },
    getFunctionList: async () => {
      return "Not Supported";
    },
    getView: async () => {
      return "Not Supported";
    },
    getStoreProcedure: async () => {
      return "Not Supported";
    },
    getFunction: async () => {
      return "Not Supported";
    },
    getTable: async (table_name) => {
      const cmd = `
        {
          "listIndexes": "${table_name}"
        }
      `;
      return await instance.query(cmd);
    },
    getTrigger: async () => {
      return "Not Supported";
    },
    getTriggerList: async () => {
      return "Not Supported";
    },
  };

  return instance;
};

export const Mongodb = {
  makeConnection: async (conn_str) => {
    return await makeMongodb(conn_str);
  },
};
