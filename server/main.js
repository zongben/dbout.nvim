import readline from "readline";
import { makeRPC } from "./rpc.js";

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout,
  terminal: false,
});

const rpc = makeRPC();

rl.on("line", async (line) => {
  try {
    const req = rpc.parseData(line);
    rpc.validRequest(req);
    const res = await rpc.exec(req);
    if (res) {
      process.stdout.write(JSON.stringify(res) + "\n");
    }
  } catch (err) {
    process.stderr.write(JSON.stringify(err) + "\n");
  }
});
