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
      AND table_type = 'BASE TABLE'
      ORDER BY table_name
    `;
    return await this.query(sql);
  }

  async getViewList() {
    const sql = `
      SELECT table_name as view_name
      FROM information_schema.tables
      WHERE table_schema = 'public'
      AND table_type = 'VIEW';
      ORDER BY table_name
    `;
    return await this.query(sql);
  }

  async getStoreProcedureList() {
    const sql = `
      SELECT 
        routine_schema AS schema_name,
        routine_name AS procedure_name
      FROM information_schema.routines
      WHERE routine_type = 'PROCEDURE'
        AND routine_schema NOT IN ('pg_catalog', 'information_schema')
      ORDER BY routine_schema, routine_name;
    `;
    return await this.query(sql);
  }

  async getFunctionList() {
    const sql = `
      SELECT 
        routine_schema AS schema_name,
        routine_name AS function_name
      FROM information_schema.routines
      WHERE routine_type = 'FUNCTION'
        AND routine_schema NOT IN ('pg_catalog', 'information_schema')
      ORDER BY routine_schema, routine_name;
    `;
    return await this.query(sql);
  }

  async getView(view_name) {
    const sql = `
      SELECT definition as 'definition'
      FROM pg_views
      WHERE viewname = '${view_name}'
    `;
    return await this.query(sql);
  }

  async getStoreProcedure(procedure_name) {
    const sql = `
      SELECT 
        pg_get_functiondef(p.oid) AS definition
      FROM pg_proc p
      JOIN pg_namespace n ON n.oid = p.pronamespace
      WHERE p.prokind = 'p'
      AND p.proname = '${procedure_name}';
    `;
    return await this.query(sql);
  }

  async getFunction(function_name) {
    const sql = `
      SELECT 
        pg_get_functiondef(p.oid) AS definition
      FROM pg_proc p
      JOIN pg_namespace n ON n.oid = p.pronamespace
      WHERE p.prokind = 'f'
      AND p.proname = '${function_name}';
    `;
    return await this.query(sql);
  }

  async getTable(table_name) {
    const sql = `
      SELECT 
        a.attnum AS column_id,
        a.attname AS column_name,
        format_type(a.atttypid, a.atttypmod) AS data_type,
        col.character_maximum_length AS max_length,
        NOT a.attnotnull AS is_nullable,
        pg_get_expr(ad.adbin, ad.adrelid) AS default_value,
        CASE WHEN ct.contype = 'p' THEN 1 ELSE 0 END AS is_pk,
        CASE WHEN ct.contype = 'u' THEN 1 ELSE 0 END AS is_unique
      FROM pg_attribute a
      JOIN pg_class c ON a.attrelid = c.oid
      JOIN pg_namespace n ON n.oid = c.relnamespace
      LEFT JOIN information_schema.columns col 
        ON col.table_schema = n.nspname AND col.table_name = c.relname AND col.column_name = a.attname
      LEFT JOIN pg_attrdef ad ON ad.adrelid = a.attrelid AND ad.adnum = a.attnum
      LEFT JOIN pg_constraint ct ON ct.conrelid = c.oid AND a.attnum = ANY(ct.conkey)
      WHERE c.relname = '${table_name}'
        AND a.attnum > 0
        AND NOT a.attisdropped
      GROUP BY a.attnum, a.attname, format_type(a.atttypid, a.atttypmod), 
               col.character_maximum_length, a.attnotnull, ad.adbin, ad.adrelid, ct.contype
      ORDER BY a.attnum;
    `;
    const result = await this.query(sql);
    result.rows = result.rows.map((item) => {
      return {
        column_name: item.column_name,
        data_type: item.data_type,
        max_length: item.max_length,
        is_nullable: item.is_nullable,
        default_value: item.default_value,
        is_pk: item.is_pk === 1 ? true : false,
        is_unique: item.is_unique === 1 ? true : false,
      };
    });
    return result;
  }

  async getTriggerList(table_name) {
    const sql = `
      SELECT tg.tgname AS trigger_name
      FROM pg_trigger tg
      JOIN pg_class tbl ON tg.tgrelid = tbl.oid
      JOIN pg_namespace ns ON tbl.relnamespace = ns.oid
      WHERE tbl.relname = '${table_name}'
      AND ns.nspname = 'public'
      AND NOT tg.tgisinternal;
    `;
    return await this.query(sql);
  }

  async getTrigger(trig_name) {
    const sql = `
      SELECT pg_get_triggerdef(t.oid, true) AS definition
      FROM pg_trigger t
      JOIN pg_class c ON t.tgrelid = c.oid
      JOIN pg_namespace n ON c.relnamespace = n.oid
      WHERE t.tgname = '${trig_name}'
      AND NOT t.tgisinternal;
    `;
    return await this.query(sql);
  }
}
