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

  {
    rules: {
      'no-unused-vars': 'off',
      'import/extensions': 'off',
      'import/no-unresolved': 'off',
      'import/prefer-default-export': 'off',
      // コンソールからのエラー特定がAnonymousで辛くなったら解除して直す
      'import/no-anonymous-default-export': 'off',

      indent: 'off',

      'arrow-body-style': 'off',
      'dot-notation': 'off',

      'react/jsx-filename-extension': 'off',
      'react/jsx-props-no-spreading': 'off',
      'react/display-name': 'off',
      'react/require-default-props': 'off',

      'react-hooks/exhaustive-deps': 'off',

      'jsx-a11y/click-events-have-key-events': 'off',
      'jsx-a11y/no-static-element-interactions': 'off',
      'jsx-a11y/anchor-is-valid': 'off',

      'react/function-component-definition': [
        'error',
        {
          namedComponents: 'arrow-function',
          unnamedComponents: 'arrow-function',
        },
      ],

      '@typescript-eslint/no-unused-vars': 'off',
      '@typescript-eslint/no-explicit-any': 'off',
    },
  },
]);

export default eslintConfig;
