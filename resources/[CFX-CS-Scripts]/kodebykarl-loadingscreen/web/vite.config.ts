import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import tailwindcss from "@tailwindcss/vite";

function fiveMHtml() {
  return {
    name: "fivem-html",
    transformIndexHtml: {
      order: "post" as const,
      handler(html: string) {
        let out = html
          .replace(/\s+crossorigin(?:="[^"]*")?/g, "")
          .replace(/<link rel="modulepreload"[^>]*>/g, "")
          .replace(/<script type="module"/g, "<script");

        const scripts: string[] = [];
        out = out.replace(/<script[^>]*src="[^"]*"[^>]*><\/script>/g, (match) => {
          scripts.push(match);
          return "";
        });

        if (scripts.length) {
          out = out.replace("</body>", `    ${scripts.join("\n    ")}\n  </body>`);
        }

        return out;
      },
    },
  };
}

export default defineConfig({
  plugins: [react(), tailwindcss(), fiveMHtml()],
  base: "./",
  build: {
    outDir: "../html",
    assetsDir: "assets",
    emptyOutDir: true,
    cssCodeSplit: false,
    modulePreload: false,
    assetsInlineLimit: 0,
    rollupOptions: {
      output: {
        format: "iife",
        name: "GrimLoadingScreen",
        inlineDynamicImports: true,
        entryFileNames: "assets/[name].js",
        chunkFileNames: "assets/[name].js",
        assetFileNames: "assets/[name][extname]",
      },
    },
  },
});
