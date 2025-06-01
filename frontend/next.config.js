const nextConfig = {
  webpack: (config, { dev, isServer }) => {
    // 本番ビルド時にテスト関連のファイルを除外
    if (process.env.NODE_ENV === 'production') {
      config.module.rules.push({
        test: /\.(spec|test)\.(js|ts)x?$|\/specHelper\/|renderWithApollo\.tsx$/,
        loader: 'ignore-loader',
      });
    }
    return config;
  },
  compress: false, // API Gatewayで表示させるためにgzip圧縮を無効化
  assetPrefix:
    process.env.NODE_ENV === 'production'
      ? 'https://d2ewo1yy2ahstj.cloudfront.net'
      : undefined,
};

module.exports = nextConfig;
