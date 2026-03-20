import React from 'react';
import { useFormContext } from 'react-hook-form';
import { useFetchDishEffortLevels } from '../../../../features/dish/fetchDishQuery';

type Props = {
  mealPosition: number;
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
          {level.minutes}分 - {level.label}
        </option>
      ))}
    </select>
  );
};

export default SelectEffortLevel;
