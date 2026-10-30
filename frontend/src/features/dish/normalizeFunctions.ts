import _ from 'lodash';
import type { infer as Infer } from 'zod';
import { DishSourceType } from './source/const';
import {
  DISH_SOURCE_RELATION_DETAIL_VALUE_TYPE,
  dishSourceRelationDetailOf,
  putDishRelationSchema,
  selectExistingDishSourceSchema,
} from './schema';

export const normalizeDishSourceRelationDetail = (
  dishSourceType: DishSourceType,
  notNormalizedDishSourceRelationDetail,
) => {
  const normalizedDishSourceRelationDetail = _.cloneDeep(
    notNormalizedDishSourceRelationDetail,
  );
  const dishSourceRelationDetailType =
    dishSourceRelationDetailOf(dishSourceType);

  if (
    dishSourceRelationDetailType ===
    DISH_SOURCE_RELATION_DETAIL_VALUE_TYPE.NO_VALUE
  ) {
    return null;
  }

  delete normalizedDishSourceRelationDetail.detailType;
  return normalizedDishSourceRelationDetail;
};

export const normalizeInputOfAddingDishWithExistingSource = (
  input,
  dishSource,
  notNormalizedDishSourceRelationDetail,
) => {
  const normalizedInput = _.cloneDeep(input);

  normalizedInput.dishSource = (() => {
    if (!dishSource.id) return null;
    return dishSource;
  })();

  normalizedInput.dishSourceRelationDetail = normalizeDishSourceRelationDetail(
    dishSource.type,
    notNormalizedDishSourceRelationDetail,
  );

  return normalizedInput;
};

type DishSourceRelationInput = {
  dishSourceRelation: Infer<typeof putDishRelationSchema>;
};

export const normalizeDishInputWithExistingSource = <
  T extends DishSourceRelationInput & {
    selectedDishSource?: Infer<typeof selectExistingDishSourceSchema>;
  },
>(
  input: T,
): T => {
  const normalizedInput = _.cloneDeep(input);
  const { selectedDishSource } = input;

  return normalizeInputOfAddingDishWithExistingSource(
    normalizedInput,
    selectedDishSource,
    normalizedInput.dishSourceRelation.dishSourceRelationDetail,
  );
};

export const normalizeDishInputWithNewSource = <
  T extends DishSourceRelationInput & {
    dishSource: { type: DishSourceType };
  },
>(
  input: T,
) => {
  const normalizedInput = _.cloneDeep(input);
  const { dishSource } = input;

  return Object.assign(normalizedInput, {
    dishSourceRelationDetail: normalizeDishSourceRelationDetail(
      dishSource.type,
      normalizedInput.dishSourceRelation.dishSourceRelationDetail,
    ),
  });
};
