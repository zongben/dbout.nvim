import { driver } from "./driver.js";

export const makeConsumer = () => {
  return {
    createConnection: async (params) => {
      const { id, dbType, connStr } = params;
      return await driver.createConnection(id, dbType, connStr);
    },
    getConnectionInfo: async (params) => {
      const { id } = params;
      return await driver.getConnectionInfo(id);
    },
    getTableList: async (params) => {
      const { id } = params;
      return await driver.getTableList(id);
    },
    getViewList: async (params) => {
      const { id } = params;
      return await driver.getViewList(id);
    },
    getStoreProcedureList: async (params) => {
      const { id } = params;
      return await driver.getStoreProcedureList(id);
    },
    getFunctionList: async (params) => {
      const { id } = params;
      return await driver.getFunctionList(id);
    },
    getView: async (params) => {
      const { id, view_name } = params;
      return await driver.getView(id, view_name);
    },
    getStoreProcedure: async (params) => {
      const { id, procedure_name } = params;
      return await driver.getStoreProcedure(id, procedure_name);
    },
    getFunction: async (params) => {
      const { id, function_name } = params;
      return await driver.getFunction(id, function_name);
    },
    query: async (params) => {
      const { id, sql } = params;
      return await driver.query(id, sql);
    },
    getTable: async (params) => {
      const { id, table_name } = params;
      return await driver.getTable(id, table_name);
    },
    getTrigger: async (params) => {
      const { id, trig_name } = params;
      return await driver.getTrigger(id, trig_name);
    },
    getTriggerList: async (params) => {
      const { id, table_name } = params;
      return await driver.getTriggerList(id, table_name);
    },
    generateSelectSQL: async (params) => {
      const { id, table_name } = params;
      return await driver.generateSelectSQL(id, table_name);
    },
    generateInsertSQL: async (params) => {
      const { id, table_name } = params;
      return await driver.generateInsertSQL(id, table_name);
    },
    generateUpdateSQL: async (params) => {
      const { id, table_name } = params;
      return await driver.generateUpdateSQL(id, table_name);
    },
    format: async (params) => {
      const { id, sql } = params;
      return await driver.format(id, sql);
    },
  };
};
