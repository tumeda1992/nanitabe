import React from 'react';
import classnames from 'classnames';
import style from './AddMealIcon.module.scss';
import useFullScreenModal from '../../../common/modal/useFullScreenModal';
import { AddMeal } from '../../../meal/MealForm';

type Props = {
  dateForAdd: Date;
  onAddSucceeded: () => void;
};

export default (props: Props) => {
  const { dateForAdd, onAddSucceeded } = props;
  const { FullScreenModal, FullScreenModalOpener, closeModal } =
    useFullScreenModal();
  return (
    <>
      <FullScreenModalOpener>
        <div className={classnames(style['icon'], style['add-meal-icon'])}>
          +
        </div>
      </FullScreenModalOpener>
      <FullScreenModal title="食事登録">
        <AddMeal
          defaultDate={dateForAdd}
          onAddSucceeded={() => {
            closeModal();
            onAddSucceeded();
          }}
        />
      </FullScreenModal>
    </>
  );
};
