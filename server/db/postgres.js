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
}
