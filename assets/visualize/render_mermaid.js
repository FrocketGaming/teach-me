#!/usr/bin/env node
// Thin wrapper around the bundled mmdc (mermaid-cli) so the diagram-maker
// subagent doesn't have to hand-write a puppeteer config file every call.
//
// Usage: node render_mermaid.js <input.mmd> <output.png> [scale]
const fs = require("fs");
const os = require("os");
const path = require("path");
const { execFileSync } = require("child_process");

const [, , inputPath, outputPath, scaleArg] = process.argv;
if (!inputPath || !outputPath) {
  console.error("Usage: node render_mermaid.js <input.mmd> <output.png> [scale]");
  process.exit(1);
}
const scale = scaleArg || "2";

// Invoke mermaid-cli's actual JS entry point directly with `node`, rather than
// its node_modules/.bin/mmdc(.cmd) shim - the Windows .cmd shim only spawns
// through a shell, and execFileSync's shell:true passes args unescaped
// (concatenated, not quoted), which is an avoidable injection surface for no
// real benefit here.
const mmdcEntry = path.join(
  __dirname,
  "node_modules",
  "@mermaid-js",
  "mermaid-cli",
  "src",
  "cli.js",
);

const cfgPath = path.join(os.tmpdir(), `teach-me-puppeteer-cfg-${process.pid}.json`);
fs.writeFileSync(cfgPath, JSON.stringify({ args: ["--no-sandbox"] }));

try {
  execFileSync(
    process.execPath, // the running node binary
    [mmdcEntry, "-i", inputPath, "-o", outputPath, "-b", "white", "-s", scale, "-p", cfgPath],
    { stdio: "inherit" },
  );
  console.log(`wrote ${outputPath}`);
} finally {
  try { fs.unlinkSync(cfgPath); } catch {}
}
