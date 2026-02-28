import { cpSync, existsSync, mkdirSync, readdirSync, rmSync, writeFileSync } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const rootDirectory = path.resolve(__dirname, "..");
const distDirectory = path.join(rootDirectory, "dist");
const resourcesDirectory = path.resolve(rootDirectory, "..", "Sources", "YiTongWebAssets", "Resources");

if (!existsSync(distDirectory)) {
  throw new Error("WebRenderer dist directory does not exist. Run `npm run build` first.");
}

mkdirSync(resourcesDirectory, { recursive: true });

for (const name of readdirSync(resourcesDirectory)) {
  rmSync(path.join(resourcesDirectory, name), { force: true, recursive: true });
}

for (const name of ["index.html", "renderer.js", "renderer.css"]) {
  cpSync(path.join(distDirectory, name), path.join(resourcesDirectory, name));
}

const manifest = {
  rendererVersion: "0.1.0-placeholder",
  protocolVersion: 1,
  files: ["index.html", "renderer.js", "renderer.css"],
};

writeFileSync(
  path.join(resourcesDirectory, "manifest.json"),
  `${JSON.stringify(manifest, null, 2)}\n`
);
