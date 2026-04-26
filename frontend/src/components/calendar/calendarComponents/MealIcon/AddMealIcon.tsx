import React, { useState } from 'react';
import classnames from 'classnames';
import style from './AddMealIcon.module.scss';
import useFullScreenModal from '../../../common/modal/useFullScreenModal';
import { AddMeal } from '../../../meal/MealForm';
import AddMealFrame from './AddMealFrame';
import AddMealPattern from './AddMealPattern';

type AddType = 'meal' | 'frame' | 'pattern';

type Props = {
  dateForAdd: Date;
  onAddSucceeded: () => void;
};

export default (props: Props) => {
  const { dateForAdd, onAddSucceeded } = props;
  const { FullScreenModal, FullScreenModalOpener, closeModal } =
    useFullScreenModal();
  const [addType, setAddType] = useState<AddType>('meal');

  const handleAddSucceeded = () => {
    closeModal();
    onAddSucceeded();
  };

  return (
    <>
      <FullScreenModalOpener>
        <div
          className={classnames(style['icon'], style['add-meal-icon'])}
          data-testid="addMealIconOpener"
        >
          +
        </div>
      </FullScreenModalOpener>
      <FullScreenModal title="食事登録">
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
          <AddMeal
            defaultDate={dateForAdd}
            onAddSucceeded={handleAddSucceeded}
          />
        )}
        {addType === 'frame' && (
          <AddMealFrame
            dateForAdd={dateForAdd}
            onAddSucceeded={handleAddSucceeded}
          />
        )}
        {addType === 'pattern' && (
          <AddMealPattern
            dateForAdd={dateForAdd}
            onAddSucceeded={handleAddSucceeded}
          />
        )}
      </FullScreenModal>
    </>
  );
};
