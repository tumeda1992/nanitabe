'use client';

import React from 'react';
import { useRouter, useParams } from 'next/navigation';
import useMealFrame from '../../../../features/mealFrame/useMealFrame';

const EditMealFramePage = () => {
  const router = useRouter();
  const params = useParams();
  const id = Number(params.id);

  const { mealFrames, updateMealFrame, UpdateMealFrameSchema } = useMealFrame();
  const mealFrame = mealFrames.find((f) => f.id === id);

  const handleSubmit = async (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    const formData = new FormData(event.currentTarget);
    const name = formData.get('name') as string;

    if (!name) return;

    await updateMealFrame(
      { mealFrame: { id, name } },
      {
        onCompleted: () => {
          router.push('/mealframes');
        },
      },
    );
  };

  if (!mealFrame) {
    return <p>読み込み中...</p>;
  }

  return (
    <div>
      <h1>食事枠の編集</h1>
      <form onSubmit={handleSubmit}>
        <div>
          <label htmlFor="name">枠名</label>
          <input
            id="name"
            name="name"
            defaultValue={mealFrame.name}
            data-testid="mealFrameName"
          />
        </div>
        <button type="submit" data-testid="submitMealFrameButton">
          更新する
        </button>
      </form>
    </div>
  );
};

export default EditMealFramePage;
