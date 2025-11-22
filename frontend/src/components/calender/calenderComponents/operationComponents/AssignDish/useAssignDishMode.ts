import { useEffect, useState } from 'react';
import useMeal from '../../../../../features/meal/useMeal';
import { MEAL_TYPE } from '../../../../../features/meal/const';
import useDish from '../../../../../features/dish/useDish';
import { parseBoolOrNull } from '../../../../../features/utils/booleanUtils';

export const ASSIGNING_DISH_MODES = {
  CHOOSING_DISH_MODE: 'CHOOSING_DISH_MODE',
  ASSIGNING_SELECTED_DISH_MODE: 'ASSIGNING_SELECTED_DISH_MODE',
};
export type AssigningDishMode =
  (typeof ASSIGNING_DISH_MODES)[keyof typeof ASSIGNING_DISH_MODES];

const useOnlyAssigningDishMode = (args: {
  calenderMode: any;
  updateCalenderMode: any;
  changeCalenderModeToDisplayCalenderMode: any;
}) => {
  const {
    calenderMode,
    updateCalenderMode,
    changeCalenderModeToDisplayCalenderMode,
  } = args;
  const inAssigningDishMode = Object.keys(ASSIGNING_DISH_MODES).some(
    (assigningDishMode) => calenderMode === assigningDishMode,
  );

  const isChoosingDishMode =
    calenderMode === ASSIGNING_DISH_MODES.CHOOSING_DISH_MODE;
  const changeCalenderModeToChoosingDishMode = () => {
    updateCalenderMode(ASSIGNING_DISH_MODES.CHOOSING_DISH_MODE);
  };
  const startAssigningDishModeGenerator = (initializeAssignDishValues) => {
    return () => {
      initializeAssignDishValues();
      updateCalenderMode(ASSIGNING_DISH_MODES.CHOOSING_DISH_MODE);
    };
  };

  const isAssigningSelectedDishMode =
    calenderMode === ASSIGNING_DISH_MODES.ASSIGNING_SELECTED_DISH_MODE;
  const changeCalenderModeToAssigningSelectedDishMode = () => {
    updateCalenderMode(ASSIGNING_DISH_MODES.ASSIGNING_SELECTED_DISH_MODE);
  };

  return {
    inAssigningDishMode,

    startAssigningDishModeGenerator,
    isChoosingDishMode,
    changeCalenderModeToChoosingDishMode,

    isAssigningSelectedDishMode,
    changeCalenderModeToAssigningSelectedDishMode,

    changeCalenderModeToDisplayCalenderMode,
  };
};

const DEFAULT_MEAL_TYPE = MEAL_TYPE.DINNER;
const useValuesAndFuncsForAddMeal = () => {
  const { addMeal } = useMeal();

  const [selectedDish, setSelectedDish] = useState(null);

  const [selectedMealType, setSelectedMealType] = useState(DEFAULT_MEAL_TYPE);

  const onDateClickForAssigningDishGenerator = ({ onCompleted }) => {
    return (date: Date) => {
      addMeal(
        {
          dishId: selectedDish!.id,
          meal: {
            date,
            mealType: selectedMealType,
          },
        },
        {
          onCompleted: () => {
            onCompleted();
          },
          onError: (error) => {},
        },
      );
    };
  };

  return {
    onDateClickForAssigningDishGenerator,
    selectedDish,
    selectDish: setSelectedDish,
    selectedMealType,
    selectMealType: setSelectedMealType,
  };
};

const useSearchedDish = (args: { selectedDish }) => {
  const { selectedDish } = args;
  const [selectedMealPositionForSearch, setSelectedMealPositionForSearch] =
    useState(null);
  const [
    searchedDishesAreRegisteredWithMeal,
    setSearchedDishesAreRegisteredWithMeal,
  ] = useState(null);

  const [searchStringForSearchingExistingDish, updateSearchString] =
    useState('');

  const {
    existingDishesForRegisteringWithMeal: dishes,
    prefetchedExistingDishesForRegisteringWithMeal: fetchedDishes,
    fetchLoading,
  } = useDish({
    fetchDishesParams: {
      fetchExistingDishesForRegisteringWithMealParams: {
        requireFetchedData: true,
        searchString: searchStringForSearchingExistingDish,
        mealPosition: selectedMealPositionForSearch,
        registeredWithMeal: parseBoolOrNull(
          searchedDishesAreRegisteredWithMeal,
        ),
        /*
          TODO:
          このデータ取得固有のクエリを作る
          （現在食事作成のものを流用しているからdishIdRegisteredWithMealという変数名に金属疲労が起きている）
          今のところ選んだやつが一番前に移動してしまうくらいしか不都合が無いが、他の不都合が出たらクエリ作成
         */
        dishIdRegisteredWithMeal: selectedDish?.id,
      },
    },
  });

  return {
    dishes: dishes || fetchedDishes,
    fetchLoading,
    selectedMealPositionForSearch,
    selectMealPosition: setSelectedMealPositionForSearch,
    searchedDishesAreRegisteredWithMeal,
    setSearchedDishesAreRegisteredWithMeal,

    searchStringForSearchingExistingDish,
    updateSearchString,
  };
};

export default (args: {
  calenderMode: any;
  updateCalenderMode: any;
  changeCalenderModeToDisplayCalenderMode: any;
  onDataChanged?: any;
}) => {
  const { onDataChanged } = args;

  const useOnlyAssigningDishModeResult = useOnlyAssigningDishMode(args);
  const useValuesAndFuncsForAddMealResult = useValuesAndFuncsForAddMeal();
  const useSearchedDishResult = useSearchedDish({
    selectedDish: useValuesAndFuncsForAddMealResult.selectedDish,
  });

  const [doContinuousRegistration, setDoContinuousRegistration] =
    useState(false);
  const toggleDoContinuousRegistration = () => {
    setDoContinuousRegistration(!doContinuousRegistration);
  };

  const {
    startAssigningDishModeGenerator,
    changeCalenderModeToDisplayCalenderMode,
    changeCalenderModeToChoosingDishMode,
  } = useOnlyAssigningDishModeResult;
  const { onDateClickForAssigningDishGenerator, selectDish, selectMealType } =
    useValuesAndFuncsForAddMealResult;
  const { updateSearchString } = useSearchedDishResult;

  const initializeAssignDishValues = () => {
    selectDish(null);
    selectMealType(DEFAULT_MEAL_TYPE);
    updateSearchString('');
  };
  const startAssigningDishMode = startAssigningDishModeGenerator(
    initializeAssignDishValues,
  );

  const onDateClickForAssigningDish = onDateClickForAssigningDishGenerator({
    onCompleted: () => {
      if (onDataChanged) onDataChanged();

      if (doContinuousRegistration) {
        selectDish(null);
        changeCalenderModeToChoosingDishMode();
      } else {
        changeCalenderModeToDisplayCalenderMode();
      }
    },
  });

  return {
    ...useOnlyAssigningDishModeResult,
    ...useValuesAndFuncsForAddMealResult,
    ...useSearchedDishResult,

    startAssigningDishMode,
    onDateClickForAssigningDish,

    doContinuousRegistration,
    toggleDoContinuousRegistration,
  };
};
