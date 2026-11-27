import { makeConsumer } from "./consumer.js";

const consumer = makeConsumer();

const METHODS = {
  CREATE_CONNECTION: "create_connection",
  CLOSE_CONNECTION: "close_connection",
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
  [METHODS.CREATE_CONNECTION]: (params) => consumer.createConnection(params),
  [METHODS.CLOSE_CONNECTION]: (params) => consumer.closeConnection(params),
  [METHODS.GET_TABLE_LIST]: (params) => consumer.getTableList(params),
  [METHODS.GET_VIEW_LIST]: (params) => consumer.getViewList(params),
  [METHODS.QUERY]: (params) => consumer.query(params),
  [METHODS.GET_STORE_PROCEDURE_LIST]: (params) =>
    consumer.getStoreProcedureList(params),
  [METHODS.GET_FUNCTION_LIST]: (params) => consumer.getFunctionList(params),
  [METHODS.GET_VIEW]: (params) => consumer.getView(params),
  [METHODS.GET_STORE_PROCEDURE]: (params) => consumer.getStoreProcedure(params),
  [METHODS.GET_FUNCTION]: (params) => consumer.getFunction(params),
  [METHODS.GET_TABLE]: (params) => consumer.getTable(params),
  [METHODS.GET_TRIGGER]: (params) => consumer.getTrigger(params),
  [METHODS.GET_TRIGGER_LIST]: (params) => consumer.getTriggerList(params),
  [METHODS.GENERATE_SELECT_SQL]: (params) => consumer.generateSelectSQL(params),
  [METHODS.GENERATE_INSERT_SQL]: (params) => consumer.generateInsertSQL(params),
  [METHODS.GENERATE_UPDATE_SQL]: (params) => consumer.generateUpdateSQL(params),
  [METHODS.FORMAT]: (params) => consumer.format(params),
  [METHODS.GET_CONNECTION_INFO]: (params) => consumer.getConnectionInfo(params),
};

export const makeRPC = () => {
  const jsonrpc = "2.0";

  const responses = {
    ok: (id, result) => {
      return {
        jsonrpc,
        result,
        id,
      };
    },
    parseError: (data) => {
      return {
        jsonrpc,
        id: null,
        error: {
          code: -32700,
          message: "Parse error",
          data,
        },
      };
    },
    invalidRequest: (id, data) => {
      return {
        jsonrpc,
        id,
        error: {
          code: -32600,
          message: "Invalid Request",
          data,
        },
      };
    },
    methodNotFound: (id, data) => {
      return {
        jsonrpc,
        id,
        error: {
          code: -32601,
          message: "Method not found",
          data,
        },
      };
    },
    invalidParams: (id, data) => {
      return {
        jsonrpc,
        id,
        error: {
          code: -32602,
          message: "Invalid params",
          data,
        },
      };
    },
    internalError: (id, data) => {
      return {
        jsonrpc,
        id,
        error: {
          code: -32603,
          message: "Internal error",
          data,
        },
      };
    },
  };

  const validRequest = (req) => {
    if (req === null || typeof req !== "object" || Array.isArray(req)) {
      return responses.invalidRequest(null, "request must be an object");
    }

    const hasId = Object.prototype.hasOwnProperty.call(req, "id");
    const id = hasId ? req.id : null;

    if (req.jsonrpc !== "2.0") {
      return responses.invalidRequest(id, "jsonrpc must be 2.0");
    }
    if (typeof req.method !== "string") {
      return responses.invalidRequest(id, "method must be a string");
    }
    if (
      req.params !== undefined &&
      (req.params === null ||
        typeof req.params !== "object" ||
        (!Array.isArray(req.params) && Object.getPrototypeOf(req.params) !== Object.prototype))
    ) {
      return responses.invalidRequest(id, "params must be an array or object");
    }
    if (hasId) {
      const type = typeof req.id;
      if (
        !(type === "string" || (type === "number" && Number.isFinite(req.id)) || req.id === null)
      ) {
        return responses.invalidRequest(null, "id must be string, number, or null");
      }
    }

    return undefined;
  };

  const exec = async (req) => {
      const err = validRequest(req);
      if (err) {
        return err;
      }

      const { id, method, params } = req;
      const isNotification = !Object.prototype.hasOwnProperty.call(req, "id");

      if (!handlers[method]) {
        return isNotification ? undefined : responses.methodNotFound(id, `${method} not found`);
      }

      try {
        const data = await handlers[method](params);
        if (isNotification) {
          return undefined;
        }
        return responses.ok(id, data === undefined ? null : data);
      } catch (err) {
        return isNotification
          ? undefined
          : responses.internalError(id, err instanceof Error ? err.message : String(err));
      }
  };

  return {
    parse: (raw) => {
      try {
        return JSON.parse(raw);
      } catch (err) {
        return responses.parseError(err.message);
      }
    },
    exec,
    execBatch: async (requests) => {
      if (!Array.isArray(requests) || requests.length === 0) {
        return responses.invalidRequest(null, "batch must contain at least one request");
      }

      const responsesForBatch = [];
      for (const request of requests) {
        const response = await exec(request);
        if (response !== undefined) {
          responsesForBatch.push(response);
        }
      }

      return responsesForBatch.length > 0 ? responsesForBatch : undefined;
    },
  };
};
