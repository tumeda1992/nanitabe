import React, { useState } from 'react';
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

  const [chooseDishSearchString, setChooseDishSearchString] = useState('');

  return (
    <>
      {isChoosingDishMode && (
        <ChooseDish
          useAssignDishModeResult={useAssignDishModeResult}
          initialSearchString={chooseDishSearchString}
          onSearchStringChange={setChooseDishSearchString}
        />
      )}

      {isAssigningSelectedDishMode && (
        <AssignChosenDishForDate
          useAssignDishModeResult={useAssignDishModeResult}
        />
      )}
    </>
  );
};
