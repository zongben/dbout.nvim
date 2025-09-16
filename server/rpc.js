import { Consumer } from "./consumer.js";

export const METHODS = {
  CREATE_CONNECTION: "create_connection",
  GET_DB_LIST: "get_db_list",
  GET_TABLE_LIST: "get_table_list",
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
    try {
      switch (method) {
        case METHODS.CREATE_CONNECTION: {
          await Consumer.createConnection(id, params);
          return this.ok(id, "");
        }
        case METHODS.GET_DB_LIST: {
          const data = await Consumer.getDbList(id);
          return this.ok(id, data);
        }
        case METHODS.GET_TABLE_LIST: {
          const data = await Consumer.getTableList(id, params);
          return this.ok(id, data);
        }
        default: {
          return this.methodNotFound(`${method} is not found`);
        }
      }
    } catch (err) {
      return this.internalError(err.stack);
    }
  }

  static ok(id, result) {
    return {
      jsonrpc: "2.0",
      result,
      id,
    };
  }

  static methodNotFound(data) {
    return {
      jsonrpc: "2.0",
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

  static internalError(data) {
    return {
      jsonrpc: "2.0",
      error: {
        code: -32603,
        message: "Internal error",
        data,
      },
    };
  }
}
