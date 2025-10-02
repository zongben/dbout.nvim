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
    try {
      rows = stmt.all();
      total = rows.length;
    } catch (err) {
      const info = stmt.run();
      rows = [];
      total = info.changes;
    }
    return {
      total,
      rows,
    };
  }

  getTableList() {
    const sql = `SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' ORDER BY name;`;
    return this.query(sql);
  }
}
