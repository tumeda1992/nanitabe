import React from 'react';
import type { Metadata } from 'next';
// TODO: bootstrapのCSSを適切に読み込む
// import 'bootstrap/dist/css/bootstrap.min.css';

export const metadata: Metadata = {
  title: 'Nanitabe',
  icons: {
    icon: '/favicon.ico',
    apple: '/webclip.jpeg',
  },
};

type Props = {
  children: React.ReactNode;
};

export default function RootLayout({ children }: Props) {
  return (
    <html lang="ja">
      <body>{children}</body>
    </html>
  );
}
