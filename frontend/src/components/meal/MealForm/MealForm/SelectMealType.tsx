import React from 'react';
import { Form } from 'react-bootstrap';
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
    <Form.Group>
      {MEAL_TYPES.map((mealType) => (
        <Form.Check
          key={mealType}
          type="radio"
          inline
          name="meal_type"
          value={mealType}
          onClick={() => {
            if (onClick) onClick(mealType);
          }}
          onChange={() => {
            if (onChange) onChange(mealType);
          }}
          checked={mealType === selectedMealType}
          label={MEAL_TYPE_LABELS[mealType]}
          id={`mealTypeOption-${mealType}`}
          data-testid={`mealTypeOption-${mealType}`}
        />
      ))}
    </Form.Group>
  );
};
