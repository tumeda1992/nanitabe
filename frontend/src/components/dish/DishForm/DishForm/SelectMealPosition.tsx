import React from 'react';
import {
  MEAL_POSITION_LABELS,
  MEAL_POSITIONS,
  MealPosition,
} from '../../../../features/dish/const';

type Props = {
  onClick?: (mealPosition: MealPosition | null) => void;
  onChange?: (mealPosition: MealPosition | null) => void;
  selectedMealPosition: MealPosition;
  existNullOption?: boolean;
};

export default (props: Props) => {
  const { onClick, onChange, selectedMealPosition, existNullOption } = props;
  return (
    <div>
      {existNullOption && (
        <span className="inline-flex items-center gap-1 mr-3">
          <input
            type="radio"
            name="meal_position"
            value=""
            onClick={() => { if (onClick) onClick(null); }}
            onChange={() => { if (onClick) onClick(null); }}
            checked={selectedMealPosition === null}
            id="mealPositionOption-null"
            data-testid="mealPositionOption-null"
          />
          <label htmlFor="mealPositionOption-null">指定なし</label>
        </span>
      )}
      {MEAL_POSITIONS.map((mealPosition) => (
        <span key={mealPosition} className="inline-flex items-center gap-1 mr-3">
          <input
            type="radio"
            name="meal_position"
            value={mealPosition}
            onClick={() => { if (onClick) onClick(mealPosition); }}
            onChange={() => { if (onChange) onChange(mealPosition); }}
            checked={mealPosition === selectedMealPosition}
            id={`mealPositionOption-${mealPosition}`}
            data-testid={`mealPositionOption-${mealPosition}`}
          />
          <label htmlFor={`mealPositionOption-${mealPosition}`}>{MEAL_POSITION_LABELS[mealPosition]}</label>
        </span>
      ))}
    </div>
  );
};
