import React from 'react';
import { Form } from 'react-bootstrap';
import classnames from 'classnames';
import style from './AssignDish.module.scss';
import ExistingDishIconForSelect from '../../../../dish/ExistingDishIcon/ExistingDishIconForSelect';
import SelectMealType from '../../../../meal/MealForm/MealForm/SelectMealType';
import SelectMealPosition from '../../../../dish/DishForm/DishForm/SelectMealPosition';
import { MealPosition } from '../../../../../features/dish/const';

type Props = {
  useAssignDishModeResult: any;
};

// TODO: ChooseDish→SelectDishに命名変更
export default (props: Props) => {
  const { useAssignDishModeResult } = props;
  const {
    changeCalenderModeToDisplayCalenderMode,
    changeCalenderModeToAssigningSelectedDishMode,
    selectedDish,
    selectDish,
    selectedMealType,
    selectMealType,
    dishes,
    fetchLoading,
    selectedMealPositionForSearch,
    selectMealPosition,
    searchedDishesAreRegisteredWithMeal,
    setSearchedDishesAreRegisteredWithMeal,
    updateSearchString,
    doContinuousRegistration,
    toggleDoContinuousRegistration,
  } = useAssignDishModeResult;

  if (!dishes && fetchLoading) return <>Loading</>;
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
                  changeCalenderModeToAssigningSelectedDishMode();
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
                changeCalenderModeToDisplayCalenderMode();
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

        <div className={style['choose-dish-form__label-and-input-container']}>
          <div className={style['choose-dish-form__label']}>位置</div>
          <SelectMealPosition
            selectedMealPosition={selectedMealPositionForSearch as MealPosition}
            onClick={(mealPosition) => {
              selectMealPosition(mealPosition);
            }}
            existNullOption
          />
        </div>

        <div className={style['choose-dish-form__label-and-input-container']}>
          <div className={style['choose-dish-form__label']}>関連食事</div>
          {[
            { value: null, checkboxValue: '', label: '指定なし' },
            { value: 'true', checkboxValue: 'true', label: '関連食事あり' },
            { value: 'false', checkboxValue: 'false', label: '関連食事なし' },
          ].map((registeredWithMealOption) => (
            <Form.Check
              type="radio"
              key={registeredWithMealOption.value}
              inline
              name="registeredWithMeal"
              value={registeredWithMealOption.checkboxValue}
              checked={
                searchedDishesAreRegisteredWithMeal ===
                registeredWithMealOption.value
              }
              onChange={() => {
                setSearchedDishesAreRegisteredWithMeal(
                  registeredWithMealOption.value,
                );
              }}
              label={registeredWithMealOption.label}
              id={`optionOfRegisteredWithMeal-${registeredWithMealOption.value}`}
            />
          ))}
        </div>

        <div className={style['choose-dish-form-select-dish__container']}>
          <Form.Control
            type="text"
            placeholder="料理を検索できます"
            data-testid="existingDishSearchWord"
            onChange={(e) => {
              updateSearchString(e.target.value);
            }}
          />
          <div>
            <div className={style['existing-dish-icon-container']}>
              {dishes.map((dish) => (
                <ExistingDishIconForSelect
                  key={dish.id}
                  dish={dish}
                  selected={dish.id === selectedDish?.id}
                  onClick={() => {
                    selectDish(dish);
                    changeCalenderModeToAssigningSelectedDishMode();
                  }}
                />
              ))}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};
