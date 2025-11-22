import React from 'react';
import { Form } from 'react-bootstrap';
import {
  MEAL_POSITION_LABELS,
  MEAL_POSITIONS,
  MealPosition,
} from '../../../../features/dish/const';

type Props = {
  onClick?: (mealPosition: MealPosition) => void;
  onChange?: (mealPosition: MealPosition) => void;
  selectedMealPosition: MealPosition;
  existNullOption?: boolean;
};

export default (props: Props) => {
  const { onClick, onChange, selectedMealPosition, existNullOption } = props;
  return (
    <Form.Group>
      {existNullOption && (
        <Form.Check
          type="radio"
          inline
          name="meal_position"
          value=""
          onClick={() => {
            if (onClick) onClick(null);
          }}
          onChange={() => {
            if (onClick) onClick(null);
          }}
          checked={selectedMealPosition === null}
          label="指定なし"
          id="mealPositionOption-null"
          data-testid="mealPositionOption-null"
        />
      )}
      {MEAL_POSITIONS.map((mealPosition) => (
        <Form.Check
          key={mealPosition}
          type="radio"
          inline
          name="meal_position"
          value={mealPosition}
          onClick={() => {
            if (onClick) onClick(mealPosition);
          }}
          onChange={() => {
            if (onChange) onChange(mealPosition);
          }}
          checked={mealPosition === selectedMealPosition}
          label={MEAL_POSITION_LABELS[mealPosition]}
          id={`mealPositionOption-${mealPosition}`}
          data-testid={`mealPositionOption-${mealPosition}`}
        />
      ))}
    </Form.Group>
  );
};
