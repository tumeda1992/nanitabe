'use client';

import React from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import MealFramePatternList from '../../components/meal/frame/pattern/MealFramePatternList';
import useMealFramePattern from '../../features/meal/frame/pattern/useMealFramePattern';

const MealFramePatternsPage = () => {
  const router = useRouter();
  const { deleteMealFramePattern } = useMealFramePattern({ requireFetchedData: false });

  const handleEditPattern = (patternId: number) => {
    router.push(`/mealframepatterns/${patternId}/edit`);
  };

  const handleDeletePattern = (_patternId: number) => {
    // 削除後の処理は MealFramePatternList 内で refetch される
  };

  return (
    <div>
      <h1>食事枠パターン一覧</h1>
      <Link href="/mealframepatterns/new">新規作成</Link>
      <MealFramePatternList
        onEditPattern={handleEditPattern}
        onDeletePattern={handleDeletePattern}
        deleteMealFramePattern={deleteMealFramePattern}
      />
    </div>
  );
};

export default MealFramePatternsPage;
