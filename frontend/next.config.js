// next.config.js
// @ts-check

/** @type {import('next').NextConfig} */
const nextConfig = (() => {
  const isProd = process.env.NODE_ENV === 'production';

  /** @type {import('next').NextConfig} */
  const baseConfig = {
    compress: false, // API Gateway で gzip させるため
    assetPrefix: isProd ? 'https://d2ewo1yy2ahstj.cloudfront.net' : undefined,
  };

  // 本番以外は特に無視しなくていいならここで返してOK
  if (!isProd) return baseConfig;

  // 本番だけ test/spec 系を ignore-loader で無視
  return {
    ...baseConfig,
    turbopack: {
      rules: {
        // x.spec.ts / x.spec.tsx / x.test.ts / x.test.tsx など
        '**/*.spec.*': {
          loaders: ['ignore-loader'],
        },
        '**/*.test.*': {
          loaders: ['ignore-loader'],
        },
        // /something/specHelper/... 配下
        '*/specHelper/**': {
          loaders: ['ignore-loader'],
        },
        // renderWithApollo.tsx 単独
        '**/renderWithApollo.tsx': {
          loaders: ['ignore-loader'],
        },
      },
    },
  };
})();

module.exports = nextConfig;
