#!/usr/bin/env node
// Rasterize a hand-authored SVG file to PNG via headless Chrome (puppeteer),
// so it can be looked at with the Read tool before it's shown to a learner.
// The Read tool does NOT render SVG text as an image - only real raster
// files - so this step is not optional.
//
// Usage: node render_svg.js <input.svg> <output.png> [scale]
const fs = require("fs");
const path = require("path");
const puppeteer = require("puppeteer");

async function main() {
  const [, , inputPath, outputPath, scaleArg] = process.argv;
  if (!inputPath || !outputPath) {
    console.error("Usage: node render_svg.js <input.svg> <output.png> [scale]");
    process.exit(1);
  }
  const scale = scaleArg ? parseFloat(scaleArg) : 2;
  const svgText = fs.readFileSync(inputPath, "utf8");

  // Parse width/height (or viewBox) from the SVG so the page/viewport can be
  // sized exactly to the drawing - avoids either clipping it or capturing a
  // huge margin of blank page around a small diagram.
  const widthMatch = svgText.match(/\bwidth="(\d+(?:\.\d+)?)/);
  const heightMatch = svgText.match(/\bheight="(\d+(?:\.\d+)?)/);
  const viewBoxMatch = svgText.match(/\bviewBox="[\d.\s-]+?\s+[\d.\s-]+?\s+(\d+(?:\.\d+)?)\s+(\d+(?:\.\d+)?)"/);
  const width = Math.ceil(
    widthMatch ? parseFloat(widthMatch[1]) : viewBoxMatch ? parseFloat(viewBoxMatch[1]) : 800,
  );
  const height = Math.ceil(
    heightMatch ? parseFloat(heightMatch[1]) : viewBoxMatch ? parseFloat(viewBoxMatch[2]) : 600,
  );

  const html = `<!doctype html><html><head><style>
    html,body{margin:0;padding:0;background:#ffffff;}
    svg{display:block;}
  </style></head><body>${svgText}</body></html>`;

  const browser = await puppeteer.launch({ args: ["--no-sandbox"] });
  try {
    const page = await browser.newPage();
    await page.setViewport({ width, height, deviceScaleFactor: scale });
    await page.setContent(html, { waitUntil: "load" });
    const el = await page.$("svg");
    if (!el) throw new Error("no <svg> root element found in the input file");
    await el.screenshot({ path: outputPath, omitBackground: false });
  } finally {
    await browser.close();
  }
  console.log(`wrote ${outputPath} (${width}x${height} @${scale}x)`);
}

main().catch((err) => {
  console.error(err.stack || String(err));
  process.exit(1);
});
