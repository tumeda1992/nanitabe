import React from 'react';

export enum CHOOSING_PUT_DISH_SOURCE_TYPE {
  CHOOSING_REGISTER_NEW_DISH_SOURCE,
  CHOOSING_USE_EXISTING_DISH_SOURCE,
}

const isChoosingRegisterNewDishSource = (
  choosingPutDishSourceType: CHOOSING_PUT_DISH_SOURCE_TYPE,
) =>
  choosingPutDishSourceType ===
  CHOOSING_PUT_DISH_SOURCE_TYPE.CHOOSING_REGISTER_NEW_DISH_SOURCE;
const isChoosingUseExistingDishSource = (
  choosingDishType: CHOOSING_PUT_DISH_SOURCE_TYPE,
) =>
  choosingDishType ===
  CHOOSING_PUT_DISH_SOURCE_TYPE.CHOOSING_USE_EXISTING_DISH_SOURCE;
export type UseChoosingPutDishSourceTypeResult = {
  choosingPutDishSourceType: CHOOSING_PUT_DISH_SOURCE_TYPE;
  setChoosingPutDishSourceType: (CHOOSING_DISH_TYPE) => void;
  choosingRegisterNewDishSource: boolean;
  choosingUseExistingDishSource: boolean;
};
export const useChoosingPutDishSourceType = (
  defaultChoosingDishType: CHOOSING_PUT_DISH_SOURCE_TYPE,
): UseChoosingPutDishSourceTypeResult => {
  const [choosingPutDishSourceType, setChoosingPutDishSourceType] =
    React.useState(defaultChoosingDishType);
  return {
    choosingPutDishSourceType,
    setChoosingPutDishSourceType,
    choosingRegisterNewDishSource: isChoosingRegisterNewDishSource(
      choosingPutDishSourceType,
    ),
    choosingUseExistingDishSource: isChoosingUseExistingDishSource(
      choosingPutDishSourceType,
    ),
  };
};
