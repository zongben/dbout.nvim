import { Consumer } from "./consumer.js";

const METHODS = {
  CREATE_CONNECTION: "create_connection",
  GET_TABLE_LIST: "get_table_list",
  GET_VIEW_LIST: "get_view_list",
  GET_STORE_PROCEDURE_LIST: "get_store_procedure_list",
  GET_FUNCTION_LIST: "get_function_list",
  GET_VIEW: "get_view",
  GET_STORE_PROCEDURE: "get_store_procedure",
  GET_FUNCTION: "get_function",
  GET_TABLE: "get_table",
  QUERY: "query",
};

const handlers = {
  [METHODS.CREATE_CONNECTION]: (params) => Consumer.createConnection(params),
  [METHODS.GET_TABLE_LIST]: (params) => Consumer.getTableList(params),
  [METHODS.GET_VIEW_LIST]: (params) => Consumer.getViewList(params),
  [METHODS.QUERY]: (params) => Consumer.query(params),
  [METHODS.GET_STORE_PROCEDURE_LIST]: (params) =>
    Consumer.getStoreProcedureList(params),
  [METHODS.GET_FUNCTION_LIST]: (params) => Consumer.getFunctionList(params),
  [METHODS.GET_VIEW]: (params) => Consumer.getView(params),
  [METHODS.GET_STORE_PROCEDURE]: (params) => Consumer.getStoreProcedure(params),
  [METHODS.GET_FUNCTION]: (params) => Consumer.getFunction(params),
  [METHODS.GET_TABLE]: (params) => Consumer.getTable(params),
};

export class RPC {
  static parseData(data) {
    try {
      return JSON.parse(data);
    } catch (err) {
      throw this.parseError(err);
    }
  }

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

  static ok(id, result) {
    return {
      jsonrpc: "2.0",
      result: JSON.stringify(result),
      id,
    };
  }

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
