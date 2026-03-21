'use client';

import React from 'react';
import { useRouter } from 'next/navigation';
import MealFrameForm from '../../../components/mealFrame/MealFrameForm';

const NewMealFramePage = () => {
  const router = useRouter();

  const handleSubmitSucceeded = () => {
    router.push('/mealframes');
  };

  return (
    <div>
      <h1>食事枠の新規作成</h1>
      <MealFrameForm onSubmitSucceeded={handleSubmitSucceeded} />
    </div>
  );
};

export default NewMealFramePage;
