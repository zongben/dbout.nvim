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

    const cmd = sql.trim().split(" ")[0].toUpperCase();
    if (["SELECT", "PRAGMA"].includes(cmd)) {
      rows = stmt.all();
    } else {
      const info = stmt.run();
      rows = [{ changes: info.changes, lastInsertRowid: info.lastInsertRowid }];
    }

    return [
      {
        total: rows.length,
        rows,
      },
    ];
  }

  getTableList() {
    const sql = `SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' ORDER BY name;`;
    return this.query(sql);
  }
}
