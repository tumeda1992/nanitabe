// next.config.js
// @ts-check

/** @type {import('next').NextConfig} */
const nextConfig = (() => {
  const isProd = process.env.NODE_ENV === 'production';

  /** @type {import('next').NextConfig} */
  const baseConfig = {
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
