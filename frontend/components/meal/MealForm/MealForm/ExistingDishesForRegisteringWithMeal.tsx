import { FieldError, useFormContext } from 'react-hook-form';
import { Form } from 'react-bootstrap';
import React, { useEffect, useState } from 'react';
import useDish from '../../../../features/dish/useDish';
import FormFieldWrapperWithLabel from '../../../common/form/FormFieldWrapperWithLabel';
import ErrorMessageIfExist from '../../../common/form/ErrorMessageIfExist';
import style from './ExistingDishesForRegisteringWithMeal.module.scss';
import ExistingDishIconForSelect, {
  NewDishIconForSelect,
} from '../../../dish/ExistingDishIcon/ExistingDishIconForSelect';

type ExistingDishesForRegisteringWithMealProps = {
  dishIdRegisteredWithMeal?: number;
  displayNewDishIconForSelect?: boolean;
  onNewDishIconForSelectClick?: any;
};

let searchTimer = null;

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

  const [searchString, setSearchString] = useState('');

  const { existingDishesForRegisteringWithMeal: dishes, fetchLoading } =
    useDish({
      fetchDishesParams: {
        fetchExistingDishesForRegisteringWithMealParams: {
          requireFetchedData: true,
          searchString,
          dishIdRegisteredWithMeal,
        },
      },
    });

  const [fetchedDishes, setFetchedDishes] = useState(null);
  useEffect(() => {
    if (dishes) {
      setFetchedDishes(dishes);
    }
  }, [dishes]);

  const [selectedDishId, setSelectedDishId] = useState(
    dishIdRegisteredWithMeal || null,
  );
  // NOTE: onClickでsetValueしたいが、初期値セットも込みで行うためにuseEffect利用
  useEffect(() => {
    setValue('dishId', selectedDishId);
  }, [selectedDishId]);

  if (!fetchedDishes && fetchLoading) return <>Loading</>;

  return (
    <FormFieldWrapperWithLabel label="料理">
      <div className={style['select-dishes-container']}>
        <Form.Control
          type="text"
          data-testid="existingDishSearchWord"
          onChange={(e) => {
            if (searchTimer !== null) clearTimeout(searchTimer);
            searchTimer = setTimeout(() => {
              setSearchString(e.target.value);
            }, 400);
          }}
        />
        <div className={style['dish-icon-container']}>
          {(dishes || fetchedDishes).map((dish) => (
            <ExistingDishIconForSelect
              key={dish.id}
              dish={dish}
              selected={dish.id === selectedDishId}
              onClick={() => {
                setSelectedDishId(dish.id);
              }}
            />
          ))}
          {displayNewDishIconForSelect && (
            <NewDishIconForSelect
              onClick={() => {
                if (onNewDishIconForSelectClick) {
                  onNewDishIconForSelectClick(searchString);
                }
              }}
              exampleDishName={searchString}
            />
          )}
        </div>
      </div>
      <ErrorMessageIfExist fieldError={errors.dishId as FieldError} />
    </FormFieldWrapperWithLabel>
  );
};
