import React from 'react';
import classnames from 'classnames';
import ExistingDishIconForDisplay from '../../../../dish/ExistingDishIcon/ExistingDishIconForDisplay';
import style from './MoveMeal.module.scss';

type Props = {
  useMoveDishModeResult: any;
};

export default (props: Props) => {
  const { useMoveDishModeResult } = props;
  const {
    selectedMeal,
    changeCalenderModeToDisplayCalenderMode,
    backToWeekOfBeforeMoveMeal,
  } = useMoveDishModeResult;
  return (
    <div>
      <div className={style['move-dish-header']}>
        <div className={style['move-dish-header-title__container']}>
          移動先の日付を選んでください
          <ExistingDishIconForDisplay dish={selectedMeal.dish} />
        </div>

        <div className={style['move-dish-header-menu__container']}>
          <div className={style['mark__wrapper']}>
            <div
              className={classnames(
                'fa fa-xmark',
                style['mark'],
                style['mark-to-click'],
              )}
              onClick={() => {
                backToWeekOfBeforeMoveMeal();
                changeCalenderModeToDisplayCalenderMode();
              }}
            />
          </div>
        </div>
      </div>
    </div>
  );
};
