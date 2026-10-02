import { copyFile, mkdir } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const websiteRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const fontsDir = path.join(websiteRoot, "public", "fonts");
await mkdir(fontsDir, { recursive: true });

const files = [
  ["node_modules/@fontsource-variable/noto-serif/files/noto-serif-vietnamese-wght-normal.woff2", "noto-serif-vietnamese.woff2"],
  ["node_modules/@fontsource-variable/noto-serif/files/noto-serif-latin-wght-normal.woff2", "noto-serif-latin.woff2"],
  ["node_modules/@fontsource/be-vietnam-pro/files/be-vietnam-pro-vietnamese-400-normal.woff2", "be-vietnam-pro-vietnamese-400.woff2"],
  ["node_modules/@fontsource/be-vietnam-pro/files/be-vietnam-pro-latin-400-normal.woff2", "be-vietnam-pro-latin-400.woff2"],
  ["node_modules/@fontsource/be-vietnam-pro/files/be-vietnam-pro-vietnamese-600-normal.woff2", "be-vietnam-pro-vietnamese-600.woff2"],
  ["node_modules/@fontsource/be-vietnam-pro/files/be-vietnam-pro-latin-600-normal.woff2", "be-vietnam-pro-latin-600.woff2"],
  ["node_modules/@fontsource/be-vietnam-pro/files/be-vietnam-pro-vietnamese-700-normal.woff2", "be-vietnam-pro-vietnamese-700.woff2"],
  ["node_modules/@fontsource/be-vietnam-pro/files/be-vietnam-pro-latin-700-normal.woff2", "be-vietnam-pro-latin-700.woff2"],
  ["node_modules/@fontsource/be-vietnam-pro/files/be-vietnam-pro-vietnamese-800-normal.woff2", "be-vietnam-pro-vietnamese-800.woff2"],
  ["node_modules/@fontsource/be-vietnam-pro/files/be-vietnam-pro-latin-800-normal.woff2", "be-vietnam-pro-latin-800.woff2"],
];

for (const [source, output] of files) {
  await copyFile(path.join(websiteRoot, source), path.join(fontsDir, output));
}

console.log(`Synced ${files.length} Vietnamese font files.`);
