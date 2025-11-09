import { useFormContext } from 'react-hook-form';
import { Form } from 'react-bootstrap';
import React, { useEffect, useState } from 'react';
import {
  CHOOSING_PUT_DISH_SOURCE_TYPE,
  UseChoosingPutDishSourceTypeResult,
} from './useChoosingPutDishSourceType';
import FormFieldWrapperWithLabel from '../../../common/form/FormFieldWrapperWithLabel';
import { parseIntOrNull } from '../../../../features/utils/numberUtils';
import { DishSourceFormRelationContent } from './DishSourceFormRelationContent';
import { DishSourceType } from '../../../../features/dish/source/const';
import { DishSourceFormContent } from '../../Source/SourceForm/SourceForm';
import {
  Dish,
  DishSourceRegisteredWithDish,
} from '../../../../lib/graphql/generated/graphql';
import useDishSource from '../../../../features/dish/source/useDishSource';

const useSelectedExistingDishSource = (setValue, preFilledDish?: Dish) => {
  // NOTE: 登録済みのレシピチェックボックス選択時のみ動かすとしてもhooksだけは動かしてから早期空レスポンスリターン
  const { dishSources } = useDishSource({
    fetchDishSourcesParams: {
      fetchDishSourcesOnlyParams: { requireFetchedData: true },
    },
  });
  const [dishSourceId, setDishSourceId] = useState(
    preFilledDish?.dishSourceRelation?.dishSourceId || null,
  );

  const selectedDishSource: DishSourceRegisteredWithDish | null = (() => {
    if (!dishSourceId || !dishSources) return null;

    return dishSources.find((dishSource) => dishSource.id === dishSourceId);
  })();
  const dishSourceRelation = (() => {
    // if (choosingRegisterNewDishSource) return null;
    if (!preFilledDish || !preFilledDish.dishSourceRelation) return null;
    if (preFilledDish.dishSourceRelation.dishSourceId !== dishSourceId)
      return null;
    return preFilledDish.dishSourceRelation;
  })();

  useEffect(() => {
    setValue('selectedDishSource.id', dishSourceId || null);
    setValue('selectedDishSource.type', selectedDishSource?.type || null);
  }, [dishSourceId, selectedDishSource]);

  return {
    dishSources,
    dishSourceId,
    setDishSourceId,
    selectedDishSource,
    dishSourceRelation,
  };
};
type DishFormOfRelatedDishSourceProps = {
  preFilledDish?: Dish;
  useChoosingPutDishSourceTypeResult: UseChoosingPutDishSourceTypeResult;
};
export const DishFormOfRelatedDishSource = (
  props: DishFormOfRelatedDishSourceProps,
) => {
  const {
    preFilledDish,
    useChoosingPutDishSourceTypeResult: {
      choosingRegisterNewDishSource,
      choosingUseExistingDishSource,
      setChoosingPutDishSourceType,
    },
  } = props;

  const { setValue, watch } = useFormContext();

  const {
    dishSources,
    dishSourceId,
    setDishSourceId,
    selectedDishSource,
    dishSourceRelation,
  } = useSelectedExistingDishSource(setValue, preFilledDish);

  return (
    <>
      <Form.Group>
        <Form.Check
          type="radio"
          inline
          name="add_put_dish_source_type"
          value={
            CHOOSING_PUT_DISH_SOURCE_TYPE.CHOOSING_USE_EXISTING_DISH_SOURCE
          }
          onChange={() =>
            setChoosingPutDishSourceType(
              CHOOSING_PUT_DISH_SOURCE_TYPE.CHOOSING_USE_EXISTING_DISH_SOURCE,
            )
          }
          checked={choosingUseExistingDishSource}
          label="登録済みの参考レシピから選択"
          id="optionOfUsingExistingDishSource"
          data-testid="optionOfUsingExistingDishSource"
        />
        <Form.Check
          type="radio"
          inline
          name="add_put_dish_source_type"
          value={
            CHOOSING_PUT_DISH_SOURCE_TYPE.CHOOSING_REGISTER_NEW_DISH_SOURCE
          }
          onChange={() =>
            setChoosingPutDishSourceType(
              CHOOSING_PUT_DISH_SOURCE_TYPE.CHOOSING_REGISTER_NEW_DISH_SOURCE,
            )
          }
          checked={choosingRegisterNewDishSource}
          label="新しく参考レシピを登録"
          id="optionOfRegisteringNewDishSource"
          data-testid="optionOfRegisteringNewDishSource"
        />
      </Form.Group>

      {/* TODO: DishSourceFormに移行 */}
      {choosingUseExistingDishSource && (
        <>
          <FormFieldWrapperWithLabel label="参考レシピ">
            {dishSources && (
              <Form.Select
                defaultValue={parseIntOrNull(dishSourceId)}
                onChange={(e) => {
                  setDishSourceId(parseIntOrNull(e.target.value));
                }}
                data-testid="existingDishSources"
              >
                <option value={null} data-testid="existingDishSource-novalue">
                  --
                </option>
                {dishSources.map((dishSource) => (
                  <option
                    key={dishSource.id}
                    value={dishSource.id}
                    data-testid={`existingDishSource-${dishSource.id}`}
                  >
                    {dishSource.name}
                  </option>
                ))}
              </Form.Select>
            )}
          </FormFieldWrapperWithLabel>
          <DishSourceFormRelationContent
            dishSourceType={selectedDishSource?.type as DishSourceType}
            dishSourceRelation={dishSourceRelation}
          />
        </>
      )}

      {choosingRegisterNewDishSource && (
        <>
          <DishSourceFormContent />
          <DishSourceFormRelationContent
            dishSourceType={
              parseIntOrNull(watch('dishSource.type')) as DishSourceType
            }
            dishSourceRelation={null}
          />
        </>
      )}
    </>
  );
};
