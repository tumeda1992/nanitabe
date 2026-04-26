'use client';

import React from 'react';
import { useRouter } from 'next/navigation';
import MealFramePatternForm from '../../../components/meal/frame/pattern/MealFramePatternForm';

const NewMealFramePatternPage = () => {
  const router = useRouter();

  const handleSubmitSucceeded = () => {
    router.push('/mealframepatterns');
  };

  return (
    <div>
      <h1>食事枠パターンの新規作成</h1>
      <MealFramePatternForm onSubmitSucceeded={handleSubmitSucceeded} />
    </div>
  );
};

export default NewMealFramePatternPage;
