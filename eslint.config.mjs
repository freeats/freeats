import pluginImport from "eslint-plugin-import";
import stylisticJs from "@stylistic/eslint-plugin-js";
import { fixupPluginRules } from "@eslint/compat";
import globals from "globals";
import path from "node:path";
import { fileURLToPath } from "node:url";
import js from "@eslint/js";
import { FlatCompat } from "@eslint/eslintrc";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const compat = new FlatCompat({
  baseDirectory: __dirname,
  recommendedConfig: js.configs.recommended,
  allConfig: js.configs.all,
});

export default [
  {
    ignores: [
      "**/bin/",
      "**/coverage/",
      "app/assets/builds/",
      "**/node_modules/",
      "**/vendor/",
      "public/assets/",
    ],
  },
  ...compat.extends("eslint:recommended"),
  {
    plugins: {
      import: fixupPluginRules(pluginImport),
      "@stylistic/js": stylisticJs,
    },

    languageOptions: {
      globals: {
        ...globals.browser,
        ...globals.commonjs,
        ...globals.node,
      },

      ecmaVersion: 2022,
      sourceType: "module",
    },

    rules: {
      "@stylistic/js/max-len": ["error", { code: 100 }],

      "@stylistic/js/quotes": ["error", "double", "avoid-escape"],
      "class-methods-use-this": "off",
      "no-alert": "off",
      "default-case": "off",

      "no-unused-vars": ["error", {
        varsIgnorePattern: "^_",
      }],

      "no-unused-expressions": ["error", {
        allowTernary: true,
      }],

      "@stylistic/js/semi": ["error", "always", {
        omitLastInOneLineBlock: true,
      }],

      "@stylistic/js/comma-dangle": ["error", "always-multiline"],

      "@stylistic/js/brace-style": "error",

      "@stylistic/js/block-spacing": ["error", "always"],

      "@stylistic/js/object-curly-spacing": ["error", "always"],

      "@stylistic/js/lines-between-class-members": ["error", "always"],
    },
  },
];
