import { makeDriver } from "./driver.js";

const driver = makeDriver();

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
  GET_INDEXES: "get_indexes",
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
  [METHODS.CREATE_CONNECTION]: ({ id, dbType, connStr, trustServer }) =>
    driver.createConnection(id, dbType, connStr, trustServer),
  [METHODS.CLOSE_CONNECTION]: ({ id }) => driver.closeConnection(id),
  [METHODS.GET_TABLE_LIST]: ({ id }) => driver.getTableList(id),
  [METHODS.GET_VIEW_LIST]: ({ id }) => driver.getViewList(id),
  [METHODS.QUERY]: ({ id, sql }) => driver.query(id, sql),
  [METHODS.GET_STORE_PROCEDURE_LIST]: ({ id }) =>
    driver.getStoreProcedureList(id),
  [METHODS.GET_FUNCTION_LIST]: ({ id }) => driver.getFunctionList(id),
  [METHODS.GET_VIEW]: ({ id, view_name }) => driver.getView(id, view_name),
  [METHODS.GET_STORE_PROCEDURE]: ({ id, procedure_name }) =>
    driver.getStoreProcedure(id, procedure_name),
  [METHODS.GET_FUNCTION]: ({ id, function_name }) =>
    driver.getFunction(id, function_name),
  [METHODS.GET_TABLE]: ({ id, table_name }) => driver.getTable(id, table_name),
  [METHODS.GET_INDEXES]: ({ id, table_name }) =>
    driver.getIndexes(id, table_name),
  [METHODS.GET_TRIGGER]: ({ id, trig_name }) =>
    driver.getTrigger(id, trig_name),
  [METHODS.GET_TRIGGER_LIST]: ({ id, table_name }) =>
    driver.getTriggerList(id, table_name),
  [METHODS.GENERATE_SELECT_SQL]: ({ id, table_name }) =>
    driver.generateSelectSQL(id, table_name),
  [METHODS.GENERATE_INSERT_SQL]: ({ id, table_name }) =>
    driver.generateInsertSQL(id, table_name),
  [METHODS.GENERATE_UPDATE_SQL]: ({ id, table_name }) =>
    driver.generateUpdateSQL(id, table_name),
  [METHODS.FORMAT]: ({ id, sql }) => driver.format(id, sql),
  [METHODS.GET_CONNECTION_INFO]: ({ id }) => driver.getConnectionInfo(id),
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
        (!Array.isArray(req.params) &&
          Object.getPrototypeOf(req.params) !== Object.prototype))
    ) {
      return responses.invalidRequest(id, "params must be an array or object");
    }
    if (hasId) {
      const type = typeof req.id;
      if (!(
        type === "string" ||
        (type === "number" && Number.isFinite(req.id)) ||
        req.id === null
      )) {
        return responses.invalidRequest(
          null,
          "id must be string, number, or null",
        );
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
      return isNotification
        ? undefined
        : responses.methodNotFound(id, `${method} not found`);
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
        : responses.internalError(
            id,
            err instanceof Error ? err.message : String(err),
          );
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
        return responses.invalidRequest(
          null,
          "batch must contain at least one request",
        );
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
