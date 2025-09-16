import readline from "readline";
import { RPC } from "./rpc.js";

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout,
  terminal: false,
});

rl.on("line", async (line) => {
  try {
    const req = RPC.parseData(line);
    RPC.validRequest(req);
    const res = await RPC.exec(req);
    process.stdout.write(JSON.stringify(res) + "\n");
  } catch (err) {
    process.stdout.write(JSON.stringify(err) + "\n");
  }
});
