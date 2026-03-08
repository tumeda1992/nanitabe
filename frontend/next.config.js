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
    async redirects() {
      return [
        {
          source: '/calender/week',
          destination: '/calendar/week',
          permanent: true,
        },
        {
          source: '/calender/week/:date',
          destination: '/calendar/week/:date',
          permanent: true,
        },
        {
          source: '/calender/month',
          destination: '/calendar/month',
          permanent: true,
        },
        {
          source: '/calender/month/:date',
          destination: '/calendar/month/:date',
          permanent: true,
        },
      ];
    },
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
