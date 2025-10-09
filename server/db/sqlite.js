import Database from "better-sqlite3";

export class Sqlite {
  #db;

  constructor(file_path) {
    this.#db = new Database(file_path);
  }

  static async createConnection(file_path) {
    return new Sqlite(file_path);
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

  getTable(table_name) {
    const indexes = this.query(`PRAGMA index_list('${table_name}');`);

    const indexMap = {};
    for (const idx of indexes.rows) {
      if (idx.unique) {
        const cols = this.query(`PRAGMA index_info('${idx.name}')`);
        for (const col of cols.rows) {
          indexMap[col.name] = idx.name;
        }
      }
    }

    const result = this.query(`PRAGMA table_info('${table_name}');`);
    result.rows = result.rows.map((item) => {
      return {
        column_name: item.name,
        data_type: item.type,
        max_length: null,
        is_nullable: item.notnull === 1 ? true : false,
        default_value: item.dflt_value,
        is_pk: item.pk === 1 ? true : false,
        is_unique: indexMap[item.column_name] ? true : false,
      };
    });
    return result;
  }

  getTriggerList(table_name) {
    const sql = `
      SELECT name AS trigger_name
      FROM sqlite_master
      WHERE type = 'trigger'
      AND tbl_name = '${table_name}';
    `;
    return this.query(sql);
  }

  getTrigger(trig_name) {
    const sql = `
      SELECT sql AS definition
      FROM sqlite_master
      WHERE type = 'trigger'
      AND name = '${trig_name}';
    `;
    return this.query(sql);
  }
}
