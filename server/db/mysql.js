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
    const start = Date.now();
    const [result, _] = await this.#pool.execute(sql);
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
