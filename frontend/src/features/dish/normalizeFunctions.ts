import _ from 'lodash';
import { DishSourceType } from './source/const';
import {
  DISH_SOURCE_RELATION_DETAIL_VALUE_TYPE,
  dishSourceRelationDetailOf,
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
