import React from 'react';
import classnames from 'classnames';
import style from './AddMealIcon.module.scss';
import useFullScreenModal from '../../../common/modal/useFullScreenModal';
import AddMealTabs from './AddMealTabs';
import { buildISODateString } from '../../../../features/utils/dateUtils';

type Props = {
  dateForAdd: Date;
  onAddSucceeded: () => void;
};

export default (props: Props) => {
  const { dateForAdd, onAddSucceeded } = props;
  const { FullScreenModal, FullScreenModalOpener, closeModal } =
    useFullScreenModal();

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
        <AddMealTabs
          defaultDate={buildISODateString(dateForAdd)}
          onAddSucceeded={handleAddSucceeded}
        />
      </FullScreenModal>
    </>
  );
};
