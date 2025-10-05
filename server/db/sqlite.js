import Database from "better-sqlite3";

export class Sqlite {
  #db;

  constructor(filePath) {
    this.#db = new Database(filePath);
  }

  static async createConnection(filePath) {
    return new Sqlite(filePath);
  }

  query(sql) {
    const stmt = this.#db.prepare(sql);

    let total, rows;
    const start = Date.now();
    try {
      rows = stmt.all();
      total = rows.length;
    } catch (err) {
      const info = stmt.run();
      rows = [];
      total = info.changes;
    }
    const end = Date.now();

    return {
      duration: `${end - start}ms`,
      total,
      rows,
    };
  }

  getTableList() {
    const sql = `SELECT name as table_name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' ORDER BY name;`;
    return this.query(sql);
  }
}
