/**
 * @template T
 * @typedef {object} QueryResult
 * @property {number} total
 * @property {T[]} rows
 */

/**
 * @typedef {object} DbList
 * @property {string} name
 */

/**
 * @typedef {object} TableList
 * @property {string} name
 */

/**
 * @typedef {object} Database
 * @property {(sql: string) => Promise<QueryResult<any>[]>} query
 * @property {() => Promise<QueryResult<DbList>[]>} getDbList
 * @property {(db_name: string) => Promise<QueryResult<TableList>[]>} getTableList
 * @property {(db_name: string) => Promise<void>} tryQueryDb
 */

/**
 * @typedef {object} JsonRpcError
 * @property {number} code
 * @property {string} message
 * @property {any} data
 */

/**
 * @typedef {object} JsonRpcReq
 * @property {string} jsonrpc
 * @property {string} method
 * @property {any} params
 * @property {string | number} [id]
 */

/**
 * @typedef {object} JsonRpcRes
 * @property {string} jsonrpc
 * @property {any} result
 * @property {string | number | null } id
 */

/**
 * @typedef {object} JsonRpcErrorRes
 * @property {string} jsonrpc
 * @property {JsonRpcError} error
 * @property {string | number} [id]
 */
