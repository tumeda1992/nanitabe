import { FieldError, useFormContext } from 'react-hook-form';
import React, { useEffect, useState } from 'react';
import ErrorMessageIfExist from '../../../common/form/ErrorMessageIfExist';
import DishSearchPanel from '../../../dish/DishSearchPanel/index';
import DishSearchCardLibrary from '../../../dish/DishSearchCard/Library';
import { type DishForSearchCard } from '../../../dish/DishSearchCard/index';
import { Button } from '@/components/ui/button';

type ExistingDishesForRegisteringWithMealProps = {
  dishIdRegisteredWithMeal?: number;
  displayNewDishIconForSelect?: boolean;
  onNewDishIconForSelectClick?: (searchString: string) => void;
  initialSearchString?: string;
};

export const ExistingDishesForRegisteringWithMeal = (
  props: ExistingDishesForRegisteringWithMealProps,
) => {
  const {
    dishIdRegisteredWithMeal,
    displayNewDishIconForSelect = false,
    onNewDishIconForSelectClick,
    initialSearchString,
  } = props;
  const {
    setValue,
    formState: { errors },
  } = useFormContext();

  const [searchString, setSearchString] = useState(initialSearchString ?? '');
  const [selectedDishId, setSelectedDishId] = useState<number | null>(
    dishIdRegisteredWithMeal || null,
  );

  useEffect(() => {
    setValue('dishId', selectedDishId);
  }, [selectedDishId]);

  const handleToggle = (dish: DishForSearchCard) => {
    setSelectedDishId((prev) => (prev === dish.id ? null : dish.id));
  };

  return (
    <>
      <DishSearchPanel
        initialSearchString={initialSearchString}
        onSearchStringChange={setSearchString}
        renderCard={(dish) => (
          <DishSearchCardLibrary
            dish={dish}
            selected={selectedDishId === dish.id}
            onToggle={() => handleToggle(dish)}
          />
        )}
      />
      {displayNewDishIconForSelect && (
        <Button
          type="button"
          variant="outline"
          size="sm"
          className="mt-2 w-full"
          onClick={() => {
            if (onNewDishIconForSelectClick) {
              onNewDishIconForSelectClick(searchString);
            }
          }}
          data-testid="existingDish-new"
        >
          新規料理を登録
        </Button>
      )}
      <ErrorMessageIfExist fieldError={errors.dishId as FieldError} />
    </>
  );
};
