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

  static async query(params) {
    const { id, sql } = params;
    return await driver.query(id, sql);
  }
}
