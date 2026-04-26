'use client';

import React from 'react';
import { useRouter, useParams } from 'next/navigation';
import useMealFramePattern from '../../../../features/meal/frame/pattern/useMealFramePattern';
import MealFramePatternEditForm from '../../../../components/meal/frame/pattern/MealFramePatternEditForm';

const EditMealFramePatternPage = () => {
  const router = useRouter();
  const params = useParams();
  const id = Number(params.id);

  const { mealFramePatterns, updateMealFramePattern } = useMealFramePattern();
  const pattern = mealFramePatterns.find((p) => p.id === id);

  const handleSubmitSucceeded = () => {
    router.push('/mealframepatterns');
  };

  if (!pattern) {
    return <p>読み込み中...</p>;
  }

  return (
    <div>
      <h1>食事枠パターンの編集</h1>
      <MealFramePatternEditForm
        pattern={pattern}
        onSubmitSucceeded={handleSubmitSucceeded}
        updateMealFramePattern={updateMealFramePattern}
      />
    </div>
  );
};

export default EditMealFramePatternPage;
