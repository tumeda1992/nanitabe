import React from 'react';
import classnames from 'classnames';
import style from './index.module.scss';
import { MealForCalender } from '../../../../lib/graphql/generated/graphql';
import { MEAL_TYPE } from '../../../../features/meal/const';
import useFloatModal from '../../../common/modal/useFloatModal';
import Menu from './Menu';
import { MEAL_POSITION } from '../../../../features/dish/const';
import { DISH_SOURCE_TYPE } from '../../../../features/dish/source/const';

type Props = {
  meal: MealForCalender;
  onChanged?: () => void;
  canAnythingExeptDisplayDishName: boolean;
  calenderModeChangers: any;
};
export default (props: Props) => {
  const {
    meal,
    onChanged,
    canAnythingExeptDisplayDishName,
    calenderModeChangers,
  } = props;
  const { dish } = meal;
  const { FloatModal, FloatModalOpener, closeModal } = useFloatModal();

  const iconCssClassOfMealType = (() => {
    const suffix = (() => {
      switch (meal.mealType) {
        case MEAL_TYPE.BREAKFAST:
          return 'breakfast';
        case MEAL_TYPE.LUNCH:
          return 'lunch';
        case MEAL_TYPE.DINNER:
          return 'dinner';
        default:
          return '';
      }
    })();
    return `meal-icon--${suffix}`;
  })();

  const mealPositionMark = (() => {
    const iconCssClass = (() => {
      if (dish?.dishSourceRelation?.type === DISH_SOURCE_TYPE.RESTAURANT) {
        return 'fa-solid fa-store';
      }

      switch (dish.mealPosition) {
        case MEAL_POSITION.STAPLE_FOOD:
          return 'fa-solid fa-bowl-rice';
        case MEAL_POSITION.MAIN_DISH:
          return 'fa-solid fa-utensils';
        case MEAL_POSITION.SIDE_DISH:
          return 'fa-solid fa-carrot';
        case MEAL_POSITION.SOUP:
          return 'fa-solid fa-mug-saucer';
        case MEAL_POSITION.DESSERT:
          return 'fa-solid fa-cookie-bite';
        default:
          return null;
      }
    })();
    if (!iconCssClass) return null;
    return (
      <i
        className={classnames(
          iconCssClass,
          style['mark-white'],
          style['dish-content-mark'],
        )}
      />
    );
  })();

  const dishName = (() => {
    if (dish.name.length <= 15) return dish.name;
    return `${dish.name.slice(0, 7)}…${dish.name.slice(-7)}`;
  })();

  const caption = (() => {
    const dishSourceCaption = (() => {
      if (!dish?.dishSourceRelation?.sourceName) return '';
      const displaySourceName = (() => {
        const { sourceName } = dish.dishSourceRelation;
        if (sourceName.length <= 5) return sourceName;
        return `${sourceName.slice(0, 5)}…`;
      })();
      const pageString = (() => {
        if (!dish.dishSourceRelation.recipeBookPage) return '';
        return ` P${dish.dishSourceRelation.recipeBookPage}`;
      })();
      return `(${displaySourceName}${pageString})`;
    })();
    const evaluationCaption = (() => {
      if (!dish?.evaluationScore) return '';
      return `★${dish.evaluationScore}`;
    })();
    return `${dishSourceCaption} ${evaluationCaption}`;
  })();

  return (
    <div className={classnames(style['icon'], style[iconCssClassOfMealType])}>
      {mealPositionMark && <>{mealPositionMark} &nbsp;</>}
      <div className={style['dish-content']}>
        <div className={style['dish-content-name-and-caption-container']}>
          <div className={style['dish-content-dishname']}>{dishName}</div>
          {caption && (
            <div className={style['dish-content-caption']}>{caption}</div>
          )}
        </div>
      </div>
      {canAnythingExeptDisplayDishName && (
        <FloatModalOpener>
          &nbsp;
          <i
            className={classnames(
              'fa-solid',
              'fa-ellipsis-vertical',
              style['meal-icon__menu-button'],
              style['dish-content-menu-opener'],
            )}
            data-testid={`mealMenuOpener-${meal.id}`}
          />
        </FloatModalOpener>
      )}
      <FloatModal>
        <Menu
          meal={meal}
          closeSelf={closeModal}
          onChanged={onChanged}
          calenderModeChangers={calenderModeChangers}
        />
      </FloatModal>
    </div>
  );
};
