'use client';

import React, { useState } from 'react';
import Link from 'next/link';
import useMealFrame from '../../../features/meal/frame/useMealFrame';

const MealFrameList = () => {
  const { mealFrames, deleteMealFrame, refetchMealFrames } = useMealFrame();
  const [deleteError, setDeleteError] = useState<string | null>(null);

  const handleDelete = async (id: number) => {
    setDeleteError(null);
    await deleteMealFrame(
      { id },
      {
        onCompleted: () => {
          if (refetchMealFrames) refetchMealFrames();
        },
        onError: (error) => {
          setDeleteError('削除できませんでした。枠にエントリが登録されている可能性があります。');
        },
      },
    );
  };

  if (mealFrames.length === 0) {
    return <p>枠がありません。</p>;
  }

  return (
    <>
      {deleteError && <p data-testid="deleteError">{deleteError}</p>}
      <ul>
        {mealFrames.map((frame) => (
          <li key={frame.id}>
            <span>{frame.name}</span>
            <Link href={`/mealframes/${frame.id}/edit`} data-testid={`editMealFrame-${frame.id}`}>
              編集
            </Link>
            <button
              type="button"
              data-testid={`deleteMealFrame-${frame.id}`}
              onClick={() => handleDelete(frame.id)}
            >
              削除
            </button>
          </li>
        ))}
      </ul>
    </>
  );
};

export default MealFrameList;
