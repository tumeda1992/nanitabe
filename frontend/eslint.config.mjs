// eslint.config.mjs
import { defineConfig, globalIgnores } from 'eslint/config';
import nextCoreWebVitals from 'eslint-config-next/core-web-vitals';
import nextTs from 'eslint-config-next/typescript';

const eslintConfig = defineConfig([
  // Next.js + Core Web Vitals 推奨セット
  ...nextCoreWebVitals,

  // TypeScript 向けのルール追加
  ...nextTs,

  // プロジェクト用の ignore
  globalIgnores(['.next/**', 'dist/**', 'node_modules/**']),
]);

export default eslintConfig;
