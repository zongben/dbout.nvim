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
    const sql = `
      SELECT name as table_name 
      FROM sqlite_master 
      WHERE type='table' 
      AND name NOT LIKE 'sqlite_%' 
      ORDER BY name;
    `;
    return this.query(sql);
  }

  getViewList() {
    const sql = `
      SELECT name as view_name
      FROM sqlite_master 
      WHERE type='view' 
      AND name NOT LIKE 'sqlite_%' 
      ORDER BY name;
    `;
    return this.query(sql);
  }

  getStoreProcedureList() {
    return "Not Supported";
  }

  getFunctionList() {
    return "Not Supported";
  }

  getView(view_name) {
    const sql = `
      SELECT sql as 'definition'
      FROM sqlite_master
      WHERE type = 'view'
      AND name = '${view_name}'
    `;
    return this.query(sql);
  }

  getStoreProcedure() {
    return "Not Supported";
  }

  getFunction() {
    return "Not Supported";
  }
}
