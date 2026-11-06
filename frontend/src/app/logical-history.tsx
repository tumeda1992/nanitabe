'use client';

import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useState,
  ReactNode,
  Suspense,
} from 'react';

import { usePathname, useSearchParams } from 'next/navigation';

/**
 * 日付移動のpushStateとNext.jsの画面遷移を共通の論理URLとして扱う。
 * ブラウザのpathとqueryを同期し、hashは表示日付の判定に含めない。
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

const browserPathAndQuery = () => {
  const url = new URL(window.location.href);
  return url.pathname + url.search;
};

const NextNavigationSync = ({ onNavigate }: { onNavigate: (path: string) => void }) => {
  const pathname = usePathname();
  const search = useSearchParams()?.toString();

  useEffect(() => {
    if (pathname == null) return;
    onNavigate(browserPathAndQuery());
  }, [pathname, search, onNavigate]);

  return null;
};

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
    return browserPathAndQuery();
  });

  const pushHistory = useCallback((pathAndQuery: string) => {
    if (typeof window === 'undefined') return;

    const next = pathAndQuery.startsWith('/')
      ? pathAndQuery
      : `/${pathAndQuery}`;

    const url = new URL(next, window.location.href);
    window.history.pushState(null, '', url.pathname + url.search + url.hash);
    setCurrentPathAndQuery(url.pathname + url.search);
  }, []);

  useEffect(() => {
    if (typeof window === 'undefined') return;

    const handlePopState = () => {
      setCurrentPathAndQuery(browserPathAndQuery());
    };

    window.addEventListener('popstate', handlePopState);
    return () => window.removeEventListener('popstate', handlePopState);
  }, []);

  return (
    <LogicalHistoryContext.Provider
      value={{ currentPathAndQuery, pushHistory }}
    >
      <Suspense fallback={null}>
        <NextNavigationSync onNavigate={setCurrentPathAndQuery} />
      </Suspense>
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
