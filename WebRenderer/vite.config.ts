import path from "node:path";
import { defineConfig } from "vite";

export default defineConfig({
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
