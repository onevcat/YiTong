import path from "node:path";
import { defineConfig } from "vite";

export default defineConfig({
  resolve: {
    alias: [
      {
        // @pierre/diffs supports an optional WASM highlighter. YiTong always
        // selects the JavaScript engine, so keep that unused dynamic import
        // out of the embedded renderer bundle.
        find: /^shiki\/wasm$/,
        replacement: path.resolve(__dirname, "src/shiki-wasm-stub.ts"),
      },
      {
        // Redirect all `import … from "shiki"` to our slim shim that bundles
        // only ~47 common languages instead of all 371+.
        find: /^shiki$/,
        replacement: path.resolve(__dirname, "src/shiki-slim.ts"),
      },
    ],
  },
  build: {
    outDir: "dist",
    emptyOutDir: true,
    lib: {
      entry: path.resolve(__dirname, "src/main.ts"),
      fileName: () => "renderer.js",
      formats: ["iife"],
      name: "YiTongRenderer",
    },
    rollupOptions: {
      output: {
        inlineDynamicImports: true,
        assetFileNames: (assetInfo) => {
          if (assetInfo.name?.endsWith(".css")) {
            return "renderer.css";
          }

          return "[name][extname]";
        },
      },
    },
  },
});
