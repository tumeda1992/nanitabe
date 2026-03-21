'use client';

import React from 'react';
import { useForm, SubmitHandler } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { Button } from '@/components/ui/button';
import useMealFrame from '../../features/mealFrame/useMealFrame';
import type { AddMealFrameInput } from '../../features/mealFrame/useMealFrame';

type Props = {
  onSubmitSucceeded: () => void;
};

export default ({ onSubmitSucceeded }: Props) => {
  const { addMealFrame, AddMealFrameSchema } = useMealFrame({
    requireFetchedData: false,
  });

  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm<AddMealFrameInput>({
    resolver: zodResolver(AddMealFrameSchema),
  });

  const onSubmit: SubmitHandler<AddMealFrameInput> = async (input) => {
    await addMealFrame(input, {
      onCompleted: () => {
        onSubmitSucceeded();
      },
    });
  };

  return (
    <form onSubmit={handleSubmit(onSubmit)}>
      <div>
        <label htmlFor="mealFrameName">枠名</label>
        <input
          id="mealFrameName"
          data-testid="mealFrameName"
          {...register('mealFrame.name')}
        />
        {errors.mealFrame?.name && (
          <p>{errors.mealFrame.name.message}</p>
        )}
      </div>
      <Button type="submit" data-testid="submitMealFrameButton">
        作成する
      </Button>
    </form>
  );
};
