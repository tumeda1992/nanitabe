import classnames from 'classnames';
import Link from 'next/link';
import React from 'react';
import useCalenderMenuComponent from '../calenderComponents/CalenderMenu/useCalenderMenuComponent';

export default (props: { useAssignDishModeResult: any }) => {
  const { useAssignDishModeResult } = props;

  const { CalenderMenuWrapper, closeModal, calenderMenuStyle } =
    useCalenderMenuComponent();
  return (
    <CalenderMenuWrapper>
      <>
        <li
          className={classnames(
            calenderMenuStyle['calender-header-float-menu__row'],
          )}
        >
          <a
            className={classnames(
              calenderMenuStyle['calender-header-float-menu__content'],
            )}
            onClick={() => {
              closeModal();
              useAssignDishModeResult.startAssigningDishMode();
            }}
            data-testid="calenderMenu-assignDish"
          >
            食事割当て
          </a>
        </li>
        <li
          className={classnames(
            calenderMenuStyle['calender-header-float-menu__row'],
          )}
        >
          <Link
            href={{
              pathname: '/calender/week/thisweek',
            }}
            className={classnames(
              calenderMenuStyle['calender-header-float-menu__content'],
            )}
          >
            今週に移動
          </Link>
        </li>
      </>
    </CalenderMenuWrapper>
  );
};
