import React from 'react';
import classnames from 'classnames';
import style from './PostponeMeal.module.scss';

type Props = {
  usePostponedMealModeResult: any;
};

export default (props: Props) => {
  const { usePostponedMealModeResult } = props;
  const {
    changeCalendarModeToDisplayCalendarMode,
    changeCalendarModeToChoosingPostponedMealMode,
    selectedPostponedMeal,
  } = usePostponedMealModeResult;

  return (
    <div>
      <div className={style['postpone-meal-header']}>
        <div className={style['postpone-meal-header-title__container']}>
          <div className={style['postpone-meal-header-title__guidance']}>
            食事を登録したい日を選んでください
          </div>
          {selectedPostponedMeal && (
            <div
              className={style['postpone-meal-header-title__dish-name']}
              data-testid="scheduleChosenPostponedMeal-dishName"
            >
              {selectedPostponedMeal.dishName}
            </div>
          )}
        </div>

        <div className={style['postpone-meal-header-menu__container']}>
          <div className={style['mark__wrapper']}>
            <div
              className={classnames('fa-solid fa-angle-up', style['mark'])}
              data-testid="scheduleChosenPostponedMeal-backBtn"
              onClick={() => {
                changeCalendarModeToChoosingPostponedMealMode();
              }}
            />
          </div>
          <div className={style['mark__wrapper']}>
            <div
              className={classnames('fa fa-xmark', style['mark'])}
              data-testid="scheduleChosenPostponedMeal-closeBtn"
              onClick={() => {
                changeCalendarModeToDisplayCalendarMode();
              }}
            />
          </div>
        </div>
      </div>
    </div>
  );
};
