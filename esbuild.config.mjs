import * as path from "path";
import rails from "esbuild-rails";
import { copy } from "esbuild-plugin-copy";
import * as esbuild from "esbuild";
import fs from "node:fs";

const result = await esbuild
  .build({
    entryPoints: [
      "entrypoints/lookbook.js",
      "entrypoints/ats.js",
      "entrypoints/recaptcha.js",
      "entrypoints/career_site.js",
    ],
    bundle: true,
    loader: {
      ".svg": "text",
    },
    sourcemap: true,
    metafile: true,
    outdir: path.join(process.cwd(), "app/assets/builds"),
    absWorkingDir: path.join(process.cwd(), "app/assets/javascript"),
    logLevel: "info",
    watch: process.argv.includes("--watch"),
    // minify also activates production mode and substitutes any cases of `process.env.NODE_ENV`
    // with "production". See https://esbuild.github.io/api/#platform.
    minify: process.env.NODE_ENV === "production",
    plugins: [rails(), copy({
      resolveFrom: path.join(process.cwd(), "public/assets"),
      assets: [
        {
          from: ["./node_modules/@tabler/icons/icons/**/*.svg"],
          to: ["./icons"],
          keepStructure: true
        }
      ]
    }
    )],
    define: {},
  })
  .catch(() => process.exit(1));

fs.writeFileSync("esbuild_meta.json", JSON.stringify(result.metafile));
