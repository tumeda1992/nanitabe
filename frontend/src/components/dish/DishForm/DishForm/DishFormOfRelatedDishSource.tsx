import { useFormContext } from 'react-hook-form';
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
      <div>
        <span className="inline-flex items-center gap-1 mr-3">
          <input
            type="radio"
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
            id="optionOfUsingExistingDishSource"
            data-testid="optionOfUsingExistingDishSource"
          />
          <label htmlFor="optionOfUsingExistingDishSource">登録済みの参考レシピから選択</label>
        </span>
        <span className="inline-flex items-center gap-1 mr-3">
          <input
            type="radio"
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
            id="optionOfRegisteringNewDishSource"
            data-testid="optionOfRegisteringNewDishSource"
          />
          <label htmlFor="optionOfRegisteringNewDishSource">新しく参考レシピを登録</label>
        </span>
      </div>

      {/* TODO: DishSourceFormに移行 */}
      {choosingUseExistingDishSource && (
        <>
          <FormFieldWrapperWithLabel label="参考レシピ">
            {dishSources && (
              <select
                className="h-9 w-full rounded-md border border-input bg-transparent px-3 py-2 text-sm shadow-sm focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring"
                defaultValue={parseIntOrNull(dishSourceId) || undefined}
                onChange={(e) => {
                  setDishSourceId(parseIntOrNull(e.target.value));
                }}
                data-testid="existingDishSources"
              >
                <option
                  value={undefined}
                  data-testid="existingDishSource-novalue"
                >
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
              </select>
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
