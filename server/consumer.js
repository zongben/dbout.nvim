import { driver } from "./driver.js";

export class Consumer {
  static async createConnection(id, params) {
    const { dbType, connStr } = params;
    return await driver.createConnection(id, dbType, connStr);
  }

  static async getDbList(id) {
    return await driver.getDbList(id);
  }

  static async getTableList(id, params) {
    const { dbName } = params;
    return await driver.getTableList(id, dbName);
  }

  static async query(id, params) {
    const { sql } = params;
    return await driver.query(id, sql);
  }
}
