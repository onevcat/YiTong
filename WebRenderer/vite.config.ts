import { defineConfig } from "vite";

export default defineConfig({
  build: {
    outDir: "dist",
    emptyOutDir: true,
    rollupOptions: {
      output: {
        entryFileNames: "renderer.js",
        chunkFileNames: "renderer.js",
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
