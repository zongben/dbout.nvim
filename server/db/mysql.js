import mysql from "mysql2/promise";
import { format } from "sql-formatter";

const makeMySql = async (conn_str) => {
  const pool = mysql.createPool(conn_str);

  const instance = {
    getConnectionInfo: async () => {
      const config = pool.config;
      return {
        host: config.host,
        port: config.port,
        user: config.user,
        password: config.password,
        database: config.database,
      };
    },
    query: async (sql) => {
      const start = Date.now();
      const [result, _] = await pool.execute(sql);
      const end = Date.now();

      let total, rows;
      if (Array.isArray(result)) {
        rows = result;
        total = result.length;
      } else {
        rows = [];
        total = result.affectedRows;
      }
      return {
        duration: `${end - start}ms`,
        total,
        rows,
      };
    },
    format: (sql) => {
      return format(sql, {
        language: "mysql",
      });
    },
    getTableList: async () => {
      const sql = `
        SELECT TABLE_NAME as table_name
        FROM information_schema.tables
        WHERE table_schema = DATABASE()
        AND table_type = 'BASE TABLE'
        ORDER BY TABLE_NAME
      `;
      return await instance.query(sql);
    },
    getViewList: async () => {
      const sql = `
        SELECT TABLE_NAME as view_name
        FROM information_schema.tables
        WHERE table_schema = DATABASE()
        AND table_type = 'VIEW'
        ORDER BY TABLE_NAME
      `;
      return await instance.query(sql);
    },
    getStoreProcedureList: async () => {
      const sql = `
        SELECT
          ROUTINE_SCHEMA as schema_name,
          ROUTINE_NAME as procedure_name
        FROM INFORMATION_SCHEMA.ROUTINES
        WHERE ROUTINE_TYPE = 'PROCEDURE'
          AND ROUTINE_SCHEMA = DATABASE()
        ORDER BY ROUTINE_NAME;
      `;
      return await instance.query(sql);
    },
    getFunctionList: async () => {
      const sql = `
        SELECT
          ROUTINE_SCHEMA as schema_name,
          ROUTINE_NAME as function_name
        FROM INFORMATION_SCHEMA.ROUTINES
        WHERE ROUTINE_TYPE = 'FUNCTION'
          AND ROUTINE_SCHEMA = DATABASE()
        ORDER BY ROUTINE_NAME;
      `;
      return await instance.query(sql);
    },
    getView: async (view_name) => {
      const sql = `
        SELECT
          VIEW_DEFINITION as definition
        FROM INFORMATION_SCHEMA.VIEWS
        WHERE TABLE_NAME = '${view_name}'
          AND TABLE_SCHEMA = DATABASE()
      `;
      return await instance.query(sql);
    },
    getStoreProcedure: async (procedure_name) => {
      const sql = `
        SELECT
          ROUTINE_DEFINITION as definition
        FROM INFORMATION_SCHEMA.ROUTINES
        WHERE ROUTINE_NAME = '${procedure_name}'
          AND ROUTINE_TYPE = 'PROCEDURE'
          AND ROUTINE_SCHEMA = DATABASE();
      `;
      return await instance.query(sql);
    },
    getFunction: async (function_name) => {
      const sql = `
        SELECT
          ROUTINE_DEFINITION as definition
        FROM INFORMATION_SCHEMA.ROUTINES
        WHERE ROUTINE_NAME = '${function_name}'
          AND ROUTINE_TYPE = 'FUNCTION'
          AND ROUTINE_SCHEMA = DATABASE();
      `;
      return await instance.query(sql);
    },
    getTable: async (table_name) => {
      const sql = `
        SELECT
          ORDINAL_POSITION AS column_id,
          COLUMN_NAME AS column_name,
          DATA_TYPE AS data_type,
          CHARACTER_MAXIMUM_LENGTH AS max_length,
          (IS_NULLABLE = 'YES') AS is_nullable,
          COLUMN_DEFAULT AS default_value,
          (COLUMN_KEY = 'PRI') AS is_pk,
          (COLUMN_KEY = 'UNI') AS is_unique
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = '${table_name}'
        ORDER BY ORDINAL_POSITION;
    `;
      const result = await instance.query(sql);
      result.rows = result.rows.map((item) => {
        return {
          column_name: item.column_name,
          data_type: item.data_type,
          max_length: item.max_length,
          is_nullable: item.is_nullable == "1" ? true : false,
          default_value: item.default_value,
          is_pk: item.is_pk === 1 ? true : false,
          is_unique: item.is_unique === 1 ? true : false,
        };
      });
      return result;
    },
    getTriggerList: async (table_name) => {
      const sql = `
        SELECT TRIGGER_NAME as trigger_name
        FROM information_schema.triggers
        WHERE EVENT_OBJECT_TABLE = '${table_name}'
        AND TRIGGER_SCHEMA = DATABASE();
      `;
      return await instance.query(sql);
    },
    getTrigger: async (trig_name) => {
      const sql = `
        SELECT ACTION_STATEMENT AS definition
        FROM information_schema.triggers
        WHERE TRIGGER_NAME = '${trig_name}'
        AND TRIGGER_SCHEMA = DATABASE();
      `;
      return await instance.query(sql);
    },
  };

  return instance;
};

export const MySql = {
  makeConnection: async (conn_str) => {
    return await makeMySql(conn_str);
  },
};
