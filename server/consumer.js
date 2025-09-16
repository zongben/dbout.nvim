import { driver } from "./driver.js";

export class Consumer {
  static async createConnection(id, params) {
    const { dbType, connStr } = params;
    await driver.createConnection(id, dbType, connStr);
  }

  static async getDbList(id) {
    return await driver.getDbList(id);
  }

  static async getTableList(id, params) {
    const { tableName } = params;
    await driver.getTableList(id, tableName);
  }
}
