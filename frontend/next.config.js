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
};

module.exports = nextConfig;
