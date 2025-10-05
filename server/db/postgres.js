import pkg from "pg";
const { Pool } = pkg;

export class Postgres {
  #pool;

  async #init(config) {
    this.#pool = new Pool(config);
  }

  static async createConnection(conn_str) {
    const instance = new Postgres();
    await instance.#init({ connectionString: conn_str });
    return instance;
  }

  async query(sql) {
    const client = await this.#pool.connect();
    try {
      const start = Date.now();
      const result = await client.query(sql);
      const end = Date.now();

      return {
        duration: `${end - start}ms`,
        total: result.rowCount,
        rows: result.rows,
      };
    } finally {
      client.release();
    }
  }

  async getTableList() {
    const sql = `
      SELECT table_name
      FROM information_schema.tables
      WHERE table_schema = 'public'
        AND table_type = 'BASE TABLE';
    `;
    return await this.query(sql);
  }
}
