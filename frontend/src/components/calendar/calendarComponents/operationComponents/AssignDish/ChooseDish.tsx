import React from 'react';
import classnames from 'classnames';
import style from './AssignDish.module.scss';
import SelectMealType from '../../../../meal/MealForm/MealForm/SelectMealType';
import DishSearchPanel from '../../../../dish/DishSearchPanel/index';
import { type DishForSearchCard } from '../../../../dish/DishSearchCard/index';

type Props = {
  useAssignDishModeResult: any;
};

// TODO: ChooseDish→SelectDishに命名変更
export default (props: Props) => {
  const { useAssignDishModeResult } = props;
  const {
    changeCalendarModeToDisplayCalendarMode,
    changeCalendarModeToAssigningSelectedDishMode,
    selectedDish,
    selectDish,
    selectedMealType,
    selectMealType,
    doContinuousRegistration,
    toggleDoContinuousRegistration,
  } = useAssignDishModeResult;

  const handleSelect = (dish: DishForSearchCard) => {
    selectDish(dish);
    changeCalendarModeToAssigningSelectedDishMode();
  };

  return (
    <div className={style['choose-dish-container']}>
      <div className={style['assign-dish-header']}>
        <div className={style['assign-dish-header-title__container']}>
          <div className={style['assign-dish-header-title']}>食事登録</div>
        </div>
        <div className={style['assign-dish-header-menu__container']}>
          {selectedDish && (
            <div className={style['mark__wrapper']}>
              <div
                className={classnames(
                  'fa-solid fa-angle-down',
                  style['mark'],
                  style['mark-to-click'],
                )}
                onClick={() => {
                  changeCalendarModeToAssigningSelectedDishMode();
                }}
              />
            </div>
          )}
          <div className={style['mark__wrapper']}>
            <div
              className={classnames(
                'fa fa-xmark',
                style['mark'],
                style['mark-to-click'],
              )}
              onClick={() => {
                changeCalendarModeToDisplayCalendarMode();
              }}
            />
          </div>
        </div>
      </div>
      <div>
        <input
          type="checkbox"
          id="continuousRegistrationCheck"
          data-testid="continuousRegistrationCheck"
          checked={doContinuousRegistration}
          onChange={() => toggleDoContinuousRegistration()}
        />
        <label htmlFor="continuousRegistrationCheck">連続登録する</label>
      </div>
      <div className={style['choose-dish-form__label-and-input-container']}>
        <div className={style['choose-dish-form__label']}>時間帯</div>
        <SelectMealType
          selectedMealType={selectedMealType}
          onClick={(mealType) => {
            selectMealType(mealType);
          }}
        />
      </div>
      <div className={style['choose-dish-main']}>
        <div className={style['choose-dish-main-border__wrapper']}>
          <div className={style['choose-dish-main-border']} />
        </div>
        <div className={style['choose-dish-main-header']}>料理</div>

        <DishSearchPanel
          mode="picker"
          selectedDishId={selectedDish?.id ?? null}
          onSelect={handleSelect}
        />
      </div>
    </div>
  );
};
