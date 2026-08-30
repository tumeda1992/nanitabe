import React from 'react';
import classnames from 'classnames';
import style from './PostponeMeal.module.scss';
import { MEAL_TYPE } from '../../../../../features/meal/const';

const MEAL_TYPE_SHORT_LABELS = {
  [MEAL_TYPE.BREAKFAST]: '朝',
  [MEAL_TYPE.LUNCH]: '昼',
  [MEAL_TYPE.DINNER]: '夜',
};

type Props = {
  usePostponedMealModeResult: any;
};

export default (props: Props) => {
  const { usePostponedMealModeResult } = props;
  const {
    changeCalendarModeToDisplayCalendarMode,
    postponedMeals,
    selectPostponedMeal,
  } = usePostponedMealModeResult;

  return (
    <div className={style['choose-postponed-meal-container']}>
      <div className={style['postpone-meal-header']}>
        <div className={style['postpone-meal-header-title__container']}>
          延期した食事
        </div>
        <div className={style['postpone-meal-header-menu__container']}>
          <div className={style['mark__wrapper']}>
            <div
              className={classnames('fa fa-xmark', style['mark'])}
              data-testid="choosePostponedMeal-closeBtn"
              onClick={() => {
                changeCalendarModeToDisplayCalendarMode();
              }}
            />
          </div>
        </div>
      </div>

      {postponedMeals.length === 0 ? (
        <div
          className={style['choose-postponed-meal-empty']}
          data-testid="choosePostponedMeal-empty"
        >
          延期した食事はありません
        </div>
      ) : (
        postponedMeals.map((postponedMeal) => (
          <div
            key={postponedMeal.id}
            className={style['choose-postponed-meal-row']}
            data-testid={`choosePostponedMeal-row-${postponedMeal.id}`}
            onClick={() => selectPostponedMeal(postponedMeal)}
          >
            <div className={style['choose-postponed-meal-row__main']}>
              <span className={style['choose-postponed-meal-row__dish-name']}>
                {postponedMeal.dishName}
              </span>
              <span className={style['choose-postponed-meal-row__meal-type']}>
                {MEAL_TYPE_SHORT_LABELS[postponedMeal.mealType]}
              </span>
            </div>
            {postponedMeal.comment && (
              <p
                className="mt-0.5 text-xs text-muted-foreground/70 italic leading-snug"
                data-testid={`choosePostponedMeal-comment-${postponedMeal.id}`}
              >
                {postponedMeal.comment}
              </p>
            )}
          </div>
        ))
      )}
    </div>
  );
};
