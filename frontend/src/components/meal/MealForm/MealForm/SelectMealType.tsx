import React from 'react';
import {
  MEAL_TYPE_LABELS,
  MEAL_TYPES,
  MealType,
} from '../../../../features/meal/const';

type Props = {
  onClick?: (mealType: MealType) => void;
  onChange?: (mealType: MealType) => void;
  selectedMealType: MealType;
};

export default (props: Props) => {
  const { onClick, onChange, selectedMealType } = props;

  return (
    <div>
      {MEAL_TYPES.map((mealType) => (
        <span key={mealType} className="inline-flex items-center gap-1 mr-3">
          <input
            type="radio"
            name="meal_type"
            value={mealType}
            onClick={() => { if (onClick) onClick(mealType); }}
            onChange={() => { if (onChange) onChange(mealType); }}
            checked={mealType === selectedMealType}
            id={`mealTypeOption-${mealType}`}
            data-testid={`mealTypeOption-${mealType}`}
          />
          <label htmlFor={`mealTypeOption-${mealType}`}>{MEAL_TYPE_LABELS[mealType]}</label>
        </span>
      ))}
    </div>
  );
};
