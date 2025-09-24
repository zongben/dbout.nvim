import { Consumer } from "./consumer.js";

/**
 * @enum {string}
 */
const METHODS = {
  CREATE_CONNECTION: "create_connection",
  GET_DB_LIST: "get_db_list",
  GET_TABLE_LIST: "get_table_list",
  QUERY: "query",
  TRY_QUERY_DB: "try_query_db",
};

const handlers = {
  [METHODS.CREATE_CONNECTION]: (/** @type {any} */ params) =>
    Consumer.createConnection(params),
  [METHODS.GET_DB_LIST]: (/** @type {any} */ params) =>
    Consumer.getDbList(params),
  [METHODS.GET_TABLE_LIST]: (/** @type {any} */ params) =>
    Consumer.getTableList(params),
  [METHODS.QUERY]: (/** @type {any} */ params) => Consumer.query(params),
  [METHODS.TRY_QUERY_DB]: (/** @type {any} */ params) =>
    Consumer.tryQueryDb(params),
};

export class RPC {
  /**
   * @param {string} data
   */
  static parseData(data) {
    try {
      return JSON.parse(data);
    } catch (err) {
      throw this.parseError(err);
    }
  }

  /**
   * @param {JsonRpcReq} decoded
   */
  static validRequest(decoded) {
    if (!decoded.jsonrpc) {
      throw this.invalidRequest("jsonrpc is required");
    }

    if (decoded.jsonrpc != "2.0") {
      throw this.invalidRequest("jsonrpc 2.0 only supported");
    }

    if (!decoded.method) {
      throw this.invalidRequest("method is required");
    }

    if (typeof decoded.method !== "string") {
      throw this.invalidRequest("method must be a string");
    }

    if (decoded.params !== undefined && typeof decoded.params !== "object") {
      throw this.invalidRequest(
        "params must be an array or object if provided",
      );
    }

    if (decoded.id !== undefined) {
      const t = typeof decoded.id;
      if (!(t === "string" || t === "number" || decoded.id === null)) {
        throw this.invalidRequest(
          "id must be string, number, or null if provided",
        );
      }
    }
  }

  /**
   * @param {{ id: string; method?: string; params?: any; }} req
   */
  static async exec(req) {
    const { id, method, params } = req;

    if (!handlers[method]) throw this.methodNotFound(id, `${method} not found`);

    try {
      const data = await handlers[method](params);
      if (data) {
        return this.ok(id, data);
      }
    } catch (err) {
      throw this.internalError(req.id, err.stack);
    }
  }

  /**
   * @param {string} id
   * @param {any} result
   * @returns {JsonRpcRes}
   */
  static ok(id, result) {
    return {
      jsonrpc: "2.0",
      result,
      id,
    };
  }

  /**
   * @param {string} id
   * @param {string} data
   * @returns {JsonRpcErrorRes}
   */
  static methodNotFound(id, data) {
    return {
      jsonrpc: "2.0",
      id,
      error: {
        code: -32601,
        message: "Method not found",
        data,
      },
    };
  }

  /**
   * @param {any} data
   * @returns {JsonRpcErrorRes}
   */
  static parseError(data) {
    return {
      jsonrpc: "2.0",
      error: {
        code: -32700,
        message: "Parse error",
        data,
      },
    };
  }

  /**
   * @param {any} data
   * @returns {JsonRpcErrorRes}
   */
  static invalidRequest(data) {
    return {
      jsonrpc: "2.0",
      error: {
        code: -32600,
        message: "Invalid Request",
        data,
      },
    };
  }

  /**
   * @param {string} id
   * @param {any} data
   * @returns {JsonRpcErrorRes}
   */
  static internalError(id, data) {
    return {
      jsonrpc: "2.0",
      id,
      error: {
        code: -32603,
        message: "Internal error",
        data,
      },
    };
  }
}
