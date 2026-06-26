import readline from "readline";
import { makeRPC } from "./rpc.js";

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout,
  terminal: false,
});

const rpc = makeRPC();

rl.on("line", async (raw) => {
  const req = rpc.parse(raw);
  if (req.error) {
    process.stdout.write(JSON.stringify(req) + "\n");
    return;
  }

  try {
    const res = await rpc.exec(req);
    if (res) {
      process.stdout.write(JSON.stringify(res) + "\n");
    }
  } catch (err) {
    process.stderr.write(
      JSON.stringify({
        id: req.id,
        err,
      }) + "\n",
    );
  }
});
