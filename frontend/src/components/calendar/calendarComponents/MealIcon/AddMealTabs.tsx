import React, { useState } from 'react';
import { parseISO } from 'date-fns';
import { AddMeal } from '../../../meal/MealForm';
import AddMealFrame from './AddMealFrame';
import AddMealPattern from './AddMealPattern';

type AddType = 'meal' | 'frame' | 'pattern';

type AddMealTabsProps = {
  defaultDate: string;
  onAddSucceeded: () => void;
};

const AddMealTabs = ({ defaultDate, onAddSucceeded }: AddMealTabsProps) => {
  const [addType, setAddType] = useState<AddType>('meal');
  const defaultDateObj = parseISO(defaultDate);

  return (
    <>
      <div data-testid="addTypeSelector" className="flex gap-2 mb-4">
        <button
          type="button"
          data-testid="addTypeMeal"
          onClick={() => setAddType('meal')}
          className={addType === 'meal' ? 'font-bold underline' : ''}
        >
          食事
        </button>
        <button
          type="button"
          data-testid="addTypeFrame"
          onClick={() => setAddType('frame')}
          className={addType === 'frame' ? 'font-bold underline' : ''}
        >
          枠
        </button>
        <button
          type="button"
          data-testid="addTypePattern"
          onClick={() => setAddType('pattern')}
          className={addType === 'pattern' ? 'font-bold underline' : ''}
        >
          枠パターン適用
        </button>
      </div>

      {addType === 'meal' && (
        <AddMeal defaultDate={defaultDateObj} onAddSucceeded={onAddSucceeded} />
      )}
      {addType === 'frame' && (
        <AddMealFrame dateForAdd={defaultDateObj} onAddSucceeded={onAddSucceeded} />
      )}
      {addType === 'pattern' && (
        <AddMealPattern dateForAdd={defaultDateObj} onAddSucceeded={onAddSucceeded} />
      )}
    </>
  );
};

export default AddMealTabs;
