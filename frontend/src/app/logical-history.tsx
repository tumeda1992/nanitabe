'use client';

import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useState,
  ReactNode,
} from 'react';

import { usePathname } from 'next/navigation';

/**
 * Next.jsのrouterで扱う物理URLでなく、SPA的にクライアント側で使う論理URLを管理するコンテキスト
 * - Next.jsのrouterも存在する
 *   - しかし、history.pushStateを行うと、ページ遷移はしないが、ページ遷移時と同様コンポーネントが再描画され、本来historyを使いたい用途と逆行するため、Next.jsのrouterは使わない
 * - 旧来のhistoryライブラリのようなものを自前で実装するイメージ
 */

type LogicalHistoryContextValue = {
  /**
   * 現在の論理URL（path + query）
   * 例: "/foo/bar?x=1"
   */
  currentPathAndQuery: string;

  /**
   * 論理的な遷移を行うための関数。
   * Next.js の router.push ではなく、
   * history.pushState を内包した「アプリ独自のナビゲーション」。
   */
  pushHistory: (to: string) => void;
};

const LogicalHistoryContext = createContext<LogicalHistoryContextValue | null>(
  null,
);

export const LogicalHistoryProvider = ({
  children,
}: {
  children: ReactNode;
}) => {
  const pathname = usePathname();

  const [currentPathAndQuery, setCurrentPathAndQuery] = useState<string>(() => {
    if (typeof window === 'undefined') {
      // 本来これでもいいが、サーバーサイドと足並みを揃える
      // return '/';
      return pathname || '/';
    }
    return window.location.pathname + window.location.search;
  });

  const pushHistory = useCallback((pathAndQuery: string) => {
    if (typeof window === 'undefined') return;

    const next = pathAndQuery.startsWith('/')
      ? pathAndQuery
      : `/${pathAndQuery}`;

    window.history.pushState(null, '', next);

    setCurrentPathAndQuery(next);
  }, []);

  useEffect(() => {
    if (typeof window === 'undefined') return;

    const handlePopState = () => {
      const next = window.location.pathname + window.location.search;
      setCurrentPathAndQuery(next);
    };

    window.addEventListener('popstate', handlePopState);
    return () => window.removeEventListener('popstate', handlePopState);
  }, []);

  return (
    <LogicalHistoryContext.Provider
      value={{ currentPathAndQuery, pushHistory }}
    >
      {children}
    </LogicalHistoryContext.Provider>
  );
};

export const useLogicalHistory = (): LogicalHistoryContextValue => {
  const ctx = useContext(LogicalHistoryContext);
  if (!ctx) {
    throw new Error(
      'useLogicalHistory must be used within LogicalHistoryProvider',
    );
  }
  return ctx;
};
