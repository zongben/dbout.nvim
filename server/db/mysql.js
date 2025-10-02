import mysql from "mysql2/promise";

export class MySql {
  #pool;

  async #init(config) {
    this.#pool = mysql.createPool(config);
  }

  static async createConnection(conn_str) {
    const instance = new MySql();
    await instance.#init(conn_str);
    return instance;
  }

  async query(sql) {
    const [rows, _] = await this.#pool.execute(sql);
    return {
      total: rows.length,
      rows,
    };
  }

  async getTableList() {
    const sql = `
      SELECT table_name AS name
      FROM information_schema.tables
      WHERE table_schema = DATABASE()
        AND table_type = 'BASE TABLE';
    `;
    return await this.query(sql);
  }
}
