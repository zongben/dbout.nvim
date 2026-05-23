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
  GET_TRIGGER: "get_trigger",
  GET_TRIGGER_LIST: "get_trigger_list",
  GENERATE_SELECT_SQL: "generate_select_sql",
  GENERATE_INSERT_SQL: "generate_insert_sql",
  GENERATE_UPDATE_SQL: "generate_update_sql",
  QUERY: "query",
  FORMAT: "format",
  GET_CONNECTION_INFO: "get_connection_info",
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
  [METHODS.GET_TRIGGER]: (params) => Consumer.getTrigger(params),
  [METHODS.GET_TRIGGER_LIST]: (params) => Consumer.getTriggerList(params),
  [METHODS.GENERATE_SELECT_SQL]: (params) => Consumer.generateSelectSQL(params),
  [METHODS.GENERATE_INSERT_SQL]: (params) => Consumer.generateInsertSQL(params),
  [METHODS.GENERATE_UPDATE_SQL]: (params) => Consumer.generateUpdateSQL(params),
  [METHODS.FORMAT]: (params) => Consumer.format(params),
  [METHODS.GET_CONNECTION_INFO]: (params) => Consumer.getConnectionInfo(params),
};

export const makeRPC = () => {
  const responses = {
    ok: (id, result) => {
      return {
        jsonrpc: "2.0",
        result: JSON.stringify(result, null, 2),
        id,
      };
    },
    methodNotFound: (id, data) => {
      return {
        jsonrpc: "2.0",
        id,
        error: {
          code: -32601,
          message: "Method not found",
          data,
        },
      };
    },
    parseError: (data) => {
      return {
        jsonrpc: "2.0",
        error: {
          code: -32700,
          message: "Parse error",
          data,
        },
      };
    },
    invalidRequest: (data) => {
      return {
        jsonrpc: "2.0",
        error: {
          code: -32600,
          message: "Invalid Request",
          data,
        },
      };
    },
    internalError: (id, data) => {
      return {
        jsonrpc: "2.0",
        id,
        error: {
          code: -32603,
          message: "Internal error",
          data,
        },
      };
    },
  };
  return {
    parseData: (data) => {
      try {
        return JSON.parse(data);
      } catch (err) {
        throw responses.parseError(err);
      }
    },
    validRequest: (decoded) => {
      if (!decoded.jsonrpc) {
        throw responses.invalidRequest("jsonrpc is required");
      }

      if (decoded.jsonrpc != "2.0") {
        throw responses.invalidRequest("jsonrpc 2.0 only supported");
      }

      if (!decoded.method) {
        throw responses.invalidRequest("method is required");
      }

      if (typeof decoded.method !== "string") {
        throw responses.invalidRequest("method must be a string");
      }

      if (decoded.params !== undefined && typeof decoded.params !== "object") {
        throw responses.invalidRequest(
          "params must be an array or object if provided",
        );
      }

      if (decoded.id !== undefined) {
        const t = typeof decoded.id;
        if (!(t === "string" || t === "number" || decoded.id === null)) {
          throw responses.invalidRequest(
            "id must be string, number, or null if provided",
          );
        }
      }
    },
    exec: async (req) => {
      const { id, method, params } = req;

      if (!handlers[method])
        throw responses.methodNotFound(id, `${method} not found`);

      try {
        const data = await handlers[method](params);
        if (data) {
          return responses.ok(id, data);
        }
      } catch (err) {
        throw responses.internalError(req.id, err.stack);
      }
    },
  };
};
