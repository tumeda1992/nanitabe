import React from 'react';
import classnames from 'classnames';
import { format } from 'date-fns';
import style from '../MoveMeal/MoveMeal.module.scss'; // TODO: 独自に作るか、共通化

type Props = {
  useSwapMealsModeResult: any;
};

export default (props: Props) => {
  const { useSwapMealsModeResult } = props;
  const {
    changeCalenderModeToDisplayCalenderMode,
    backToWeekOfBeforeSwapMeal,
    swapTargetDate1,
  } = useSwapMealsModeResult;
  return (
    <div>
      <div className={style['move-dish-header']}>
        <div className={style['move-dish-header-title__container']}>
          交換したい先の日付を選んでください（交換元:{' '}
          {format(swapTargetDate1, 'yyyy年MM月dd日')}）
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
                backToWeekOfBeforeSwapMeal();
                changeCalenderModeToDisplayCalenderMode();
              }}
            />
          </div>
        </div>
      </div>
    </div>
  );
};
