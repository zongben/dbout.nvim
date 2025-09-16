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

  static exec(req) {
    switch (req.method) {
      default:
        throw this.methodNotFound(`${req.method} is not found`);
    }
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
}
