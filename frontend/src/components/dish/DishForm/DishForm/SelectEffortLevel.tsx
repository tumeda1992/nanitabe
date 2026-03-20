import React from 'react';
import { useFormContext } from 'react-hook-form';
import { useFetchDishEffortLevels } from '../../../../features/dish/fetchDishQuery';

type Props = {
  mealPosition: number;
};

const formatMinutes = (minutes: number): string => {
  if (minutes < 60) return `${minutes}分`;
  const hours = Math.floor(minutes / 60);
  const remaining = minutes % 60;
  return remaining === 0 ? `${hours}時間` : `${hours}時間${remaining}分`;
};

const SelectEffortLevel = ({ mealPosition }: Props) => {
  const { register } = useFormContext();
  const { dishEffortLevels, fetchDishEffortLevelsLoading } =
    useFetchDishEffortLevels({ mealPosition });

  if (fetchDishEffortLevelsLoading) {
    return <div>読み込み中...</div>;
  }

  return (
    <select
      {...register('dish.dishEffortLevelId', { valueAsNumber: true })}
      data-testid="dishEffortLevelSelect"
    >
      <option value="">指定なし</option>
      {dishEffortLevels.map((level) => (
        <option key={level.id} value={level.id}>
          {formatMinutes(level.minutes)} - {level.label}
        </option>
      ))}
    </select>
  );
};

export default SelectEffortLevel;
