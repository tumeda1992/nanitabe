import React, { use } from 'react';
import ClientPage from './page.client';

export default async ({ params }: { params: Promise<{ dishId: string }> }) => {
  const { dishId } = await params;

  // NOTE: 暫定対応
  // パスパラメータを取得する await params がサーバサイドでしか機能せず、
  // Editを表示するためのuseDishで使うLazyQueryがuseRefとかを使う関係でクライアントサイドでしか機能しないため、
  // サーバサイドコンポーネントからクライアントサイドコンポーネントにパスパラメータを渡す形で対応している。
  return <ClientPage dishIdString={dishId as string} />;
};
