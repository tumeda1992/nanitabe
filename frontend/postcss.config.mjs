// Tailwind CSS は tailwindcss CLI で独立コンパイル（entrypoint.sh 参照）
// @tailwindcss/postcss を PostCSS に統合するとTurbopackのdev compile が2分超になるため削除
export default {
  plugins: {},
};
