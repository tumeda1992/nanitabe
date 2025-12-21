// next.config.js
// @ts-check

/** @type {import('next').NextConfig} */
const nextConfig = (() => {
  const isProd = process.env.NODE_ENV === 'production';

  /** @type {import('next').NextConfig} */
  const baseConfig = {
    compress: false, // API Gateway で gzip させるため
    // 環境変数で出し分けられるようにする（サーバでクライアントでも読めるように接頭辞をつける）
    // assetPrefix: isProd ? 'https://d2ewo1yy2ahstj.cloudfront.net' : undefined, // prod用
    // assetPrefix: isProd ? 'https://d1qmtpt8svn0j2.cloudfront.net' : undefined, //verify-infra用
    assetPrefix: isProd ? process.env.NEXT_PUBLIC_ASSET_ORIGIN : undefined,
  };

  if (!isProd) return baseConfig;

  return {
    ...baseConfig,
    turbopack: {
      rules: {
        '**/*.spec.*': {
          loaders: ['ignore-loader'],
        },
        '**/*.test.*': {
          loaders: ['ignore-loader'],
        },
        '*/specHelper/**': {
          loaders: ['ignore-loader'],
        },
        '**/renderWithApollo.tsx': {
          loaders: ['ignore-loader'],
        },
      },
    },
  };
})();

module.exports = nextConfig;
