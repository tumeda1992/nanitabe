import React from 'react';
import style from './AssignDish.module.scss';
import ChooseDish from './ChooseDish';
import AssignChosenDishForDate from './AssignChosenDishForDate';

type Props = {
  useAssignDishModeResult: any;
};

export default (props: Props) => {
  const { useAssignDishModeResult } = props;
  const { isChoosingDishMode, isAssigningSelectedDishMode } =
    useAssignDishModeResult;

  return (
    <>
      {isChoosingDishMode && (
        <ChooseDish useAssignDishModeResult={useAssignDishModeResult} />
      )}

      {isAssigningSelectedDishMode && (
        <AssignChosenDishForDate
          useAssignDishModeResult={useAssignDishModeResult}
        />
      )}
    </>
  );
};
