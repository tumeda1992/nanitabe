import { FieldError, useFormContext } from 'react-hook-form';
import React, { useEffect, useState } from 'react';
import FormFieldWrapperWithLabel from '../../../common/form/FormFieldWrapperWithLabel';
import ErrorMessageIfExist from '../../../common/form/ErrorMessageIfExist';
import DishSearchPanel from '../../../dish/DishSearchPanel/index';
import { type DishForSearchCard } from '../../../dish/DishSearchCard/index';
import { Button } from '@/components/ui/button';

type ExistingDishesForRegisteringWithMealProps = {
  dishIdRegisteredWithMeal?: number;
  displayNewDishIconForSelect?: boolean;
  onNewDishIconForSelectClick?: any;
};

export const ExistingDishesForRegisteringWithMeal = (
  props: ExistingDishesForRegisteringWithMealProps,
) => {
  const {
    dishIdRegisteredWithMeal,
    displayNewDishIconForSelect = false,
    onNewDishIconForSelectClick,
  } = props;
  const {
    setValue,
    formState: { errors },
  } = useFormContext();

  const [selectedDishId, setSelectedDishId] = useState<number | null>(
    dishIdRegisteredWithMeal || null,
  );

  useEffect(() => {
    setValue('dishId', selectedDishId);
  }, [selectedDishId]);

  const handleSelect = (dish: DishForSearchCard) => {
    setSelectedDishId(dish.id);
  };

  return (
    <>
      <DishSearchPanel
        mode="library"
        selectedDishId={selectedDishId}
        onSelect={handleSelect}
      />
      {displayNewDishIconForSelect && (
        <Button
          type="button"
          variant="outline"
          size="sm"
          className="mt-2 w-full"
          onClick={() => {
            if (onNewDishIconForSelectClick) {
              onNewDishIconForSelectClick('');
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
