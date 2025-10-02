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
    let rows;
    try {
      rows = stmt.all();
      return {
        total: rows.length,
        rows,
      };
    } catch (err) {
      const info = stmt.run();
      return {
        total: info.changes,
        rows: [],
      };
    }
  }

  getTableList() {
    const sql = `SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' ORDER BY name;`;
    return this.query(sql);
  }
}
