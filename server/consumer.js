import { driver } from "./driver.js";

export class Consumer {
  /**
   * @param {{ id: string; dbType: string; connStr: any; }} params
   */
  static async createConnection(params) {
    const { id, dbType, connStr } = params;
    return await driver.createConnection(id, dbType, connStr);
  }

  /**
   * @param {{ id: string; }} params
   */
  static async getDbList(params) {
    const { id } = params;
    return await driver.getDbList(id);
  }

  /**
   * @param {{ id: string; dbName: string; }} params
   */
  static async getTableList(params) {
    const { id, dbName } = params;
    return await driver.getTableList(id, dbName);
  }

  /**
   * @param {{ id: string; sql: string; }} params
   */
  static async query(params) {
    const { id, sql } = params;
    return await driver.query(id, sql);
  }

  /**
   * @param {{ id: string; dbName: string; }} params
   */
  static async tryQueryDb(params) {
    const { id, dbName } = params;
    return await driver.tryQueryDb(id, dbName);
  }
}
