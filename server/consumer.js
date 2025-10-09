import { driver } from "./driver.js";

export class Consumer {
  static async createConnection(params) {
    const { id, dbType, connStr } = params;
    return await driver.createConnection(id, dbType, connStr);
  }

  static async getTableList(params) {
    const { id } = params;
    return await driver.getTableList(id);
  }

  static async getViewList(params) {
    const { id } = params;
    return await driver.getViewList(id);
  }

  static async getStoreProcedureList(params) {
    const { id } = params;
    return await driver.getStoreProcedureList(id);
  }

  static async getFunctionList(params) {
    const { id } = params;
    return await driver.getFunctionList(id);
  }

  static async getView(params) {
    const { id, view_name } = params;
    return await driver.getView(id, view_name);
  }

  static async getStoreProcedure(params) {
    const { id, procedure_name } = params;
    return await driver.getStoreProcedure(id, procedure_name);
  }

  static async getFunction(params) {
    const { id, function_name } = params;
    return await driver.getFunction(id, function_name);
  }

  static async query(params) {
    const { id, sql } = params;
    return await driver.query(id, sql);
  }

  static async getTable(params) {
    const { id, table_name } = params;
    return await driver.getTable(id, table_name);
  }

  static async getTrigger(params) {
    const { id, trig_name } = params;
    return await driver.getTrigger(id, trig_name);
  }

  static async getTriggerList(params) {
    const { id, table_name } = params;
    return await driver.getTriggerList(id, table_name);
  }

  static async generateSelectSQL(params) {
    const { id, table_name } = params;
    return await driver.generateSelectSQL(id, table_name);
  }

  static async generateInsertSQL(params) {
    const { id, table_name } = params;
    return await driver.generateInsertSQL(id, table_name);
  }

  static async generateUpdateSQL(params) {
    const { id, table_name } = params;
    return await driver.generateUpdateSQL(id, table_name);
  }
}
