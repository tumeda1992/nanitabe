import React from 'react';

export enum CHOOSING_DISH_TYPE {
  CHOOSING_REGISTER_NEW_DISH,
  CHOOSING_USE_EXISTING_DISH,
}

const isChoosingRegisterNewDish = (choosingDishType: CHOOSING_DISH_TYPE) =>
  choosingDishType === CHOOSING_DISH_TYPE.CHOOSING_REGISTER_NEW_DISH;
const isChoosingUseExistingDish = (choosingDishType: CHOOSING_DISH_TYPE) =>
  choosingDishType === CHOOSING_DISH_TYPE.CHOOSING_USE_EXISTING_DISH;
export type UseChoosingDishTypeResult = {
  choosingDishType: CHOOSING_DISH_TYPE;
  setChoosingDishType: (CHOOSING_DISH_TYPE) => void;
  choosingRegisterNewDish: boolean;
  choosingUseExistingDish: boolean;
};
export const useChoosingDishType = (
  defaultChoosingDishType: CHOOSING_DISH_TYPE,
): UseChoosingDishTypeResult => {
  const [choosingDishType, setChoosingDishType] = React.useState(
    defaultChoosingDishType,
  );
  return {
    choosingDishType,
    setChoosingDishType,
    choosingRegisterNewDish: isChoosingRegisterNewDish(choosingDishType),
    choosingUseExistingDish: isChoosingUseExistingDish(choosingDishType),
  };
};
