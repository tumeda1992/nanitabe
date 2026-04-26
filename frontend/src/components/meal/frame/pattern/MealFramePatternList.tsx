'use client';

import React from 'react';
import useMealFramePattern from '../../../../features/meal/frame/pattern/useMealFramePattern';
import type { DeleteMealFramePatternFunc } from '../../../../features/meal/frame/pattern/useMealFramePattern';

type Props = {
  onEditPattern: (patternId: number) => void;
  onDeletePattern: (patternId: number) => void;
  deleteMealFramePattern?: DeleteMealFramePatternFunc;
};

export default ({ onEditPattern, onDeletePattern, deleteMealFramePattern }: Props) => {
  const { mealFramePatterns, fetchMealFramePatternsLoading, refetchMealFramePatterns } = useMealFramePattern();

  if (fetchMealFramePatternsLoading && mealFramePatterns.length === 0) {
    return <div>読み込み中...</div>;
  }

  if (mealFramePatterns.length === 0) {
    return <div>パターンがまだ登録されていません。</div>;
  }

  const maxDayOffset = (entries: { dayOffset: number }[]) => {
    if (entries.length === 0) return 0;
    return Math.max(...entries.map((e) => e.dayOffset));
  };

  return (
    <ul>
      {mealFramePatterns.map((pattern) => (
        <li key={pattern.id} data-testid={`patternItem-${pattern.id}`}>
          <span>{pattern.name}</span>
          <span>（{maxDayOffset(pattern.entries)}日分、{pattern.entries.length}件）</span>
          <a
            href={`/mealframepatterns/${pattern.id}/edit`}
            data-testid={`editPattern-${pattern.id}`}
          >
            編集
          </a>
          <button
            type="button"
            data-testid={`deletePattern-${pattern.id}`}
            onClick={() => {
              if (deleteMealFramePattern && window.confirm(`「${pattern.name}」を削除しますか？`)) {
                deleteMealFramePattern(
                  { id: pattern.id },
                  {
                    onCompleted: () => {
                      refetchMealFramePatterns();
                    },
                  },
                );
              }
              onDeletePattern(pattern.id);
            }}
          >
            削除
          </button>
        </li>
      ))}
    </ul>
  );
};
