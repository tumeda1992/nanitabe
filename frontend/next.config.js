const nextConfig = {
  webpack: (config, { dev, isServer }) => {
    // 本番ビルド時にテスト関連のファイルを除外
    if (process.env.NODE_ENV === 'production') {
      config.module.rules.push({
        test: /\.(spec|test)\.(js|ts)x?$|\/specHelper\//,
        loader: 'ignore-loader',
      });
    }
    return config;
  },
};

module.exports = nextConfig;
