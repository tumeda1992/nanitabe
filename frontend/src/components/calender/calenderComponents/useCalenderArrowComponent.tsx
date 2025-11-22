import React from 'react';
import style from './Calender/index.module.scss';

export default (props: { refreshToPrev: any; refreshToNext: any }) => {
  const { refreshToPrev, refreshToNext } = props;

  const PreviousWeekDisplayButton = () => {
    return (
      <div
        className={style['move-date-button']}
        onClick={() => {
          refreshToPrev();
        }}
      >
        ▲
      </div>
    );
  };

  const NextWeekDisplayButton = () => {
    return (
      <div
        className={style['move-date-button']}
        onClick={() => {
          refreshToNext();
        }}
      >
        ▼
      </div>
    );
  };

  return {
    PreviousWeekDisplayButton,
    NextWeekDisplayButton,
  };
};
