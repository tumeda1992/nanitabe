import { gql } from '@apollo/client';
import * as z from 'zod';
import _ from 'lodash';
import {
  newDishSchema,
  putDishRelationSchema,
  selectExistingDishSourceSchema,
  dishTagsSchema,
} from './schema';
import {
  buildMutationExecutor,
  MutationCallbacks,
} from '../utils/mutationUtils';
import {
  AddDishMutation,
  AddDishWithNewSourceMutation,
  useAddDishMutation,
  useAddDishWithNewSourceMutation,
} from '../../lib/graphql/generated/graphql';
import { newDishSourceSchema } from './source/schema';
import {
  normalizeDishSourceRelationDetail,
  normalizeInputOfAddingDishWithExistingSource,
} from './normalizeFunctions';

export const ADD_DISH = gql`
  mutation addDish(
    $dish: DishForCreate!
    $dishSource: SourceForRead
    $dishSourceRelationDetail: DishSourceRelationDetail
    $dishTags: [Tag!]
  ) {
    addDish(
      input: {
        dish: $dish
        dishSource: $dishSource
        dishSourceRelationDetail: $dishSourceRelationDetail
        dishTags: $dishTags
      }
    ) {
      dishId
    }
  }
`;

export const AddDishSchema = z.object({
  dish: newDishSchema,
  selectedDishSource: selectExistingDishSourceSchema,
  dishSourceRelation: putDishRelationSchema,
  dishTags: dishTagsSchema,
});

export type AddDish = z.infer<typeof AddDishSchema>;

const convertFromAddDishInputToGraphqlInput = (input: AddDish): AddDish => {
  const normalizedInput = _.cloneDeep(input);
  const { selectedDishSource } = input;

  return normalizeInputOfAddingDishWithExistingSource(
    normalizedInput,
    selectedDishSource,
    normalizedInput.dishSourceRelation.dishSourceRelationDetail,
  );
};

export const ADD_DISH_WITH_NEW_SOURCE = gql`
  mutation addDishWithNewSource(
    $dish: DishForCreate!
    $dishSource: SourceForCreate!
    $dishSourceRelationDetail: DishSourceRelationDetail
    $dishTags: [Tag!]
  ) {
    addDishWithNewSource(
      input: {
        dish: $dish
        dishSource: $dishSource
        dishSourceRelationDetail: $dishSourceRelationDetail
        dishTags: $dishTags
      }
    ) {
      dishId
      dishSourceId
    }
  }
`;

export const AddDishWithNewSourceSchema = z.object({
  dish: newDishSchema,
  dishSource: newDishSourceSchema,
  dishSourceRelation: putDishRelationSchema,
  dishTags: dishTagsSchema,
});

export type AddDishWithNewSource = z.infer<typeof AddDishWithNewSourceSchema>;

const convertFromAddDishWithNewSourceInputToGraphqlInput = (
  input: AddDishWithNewSource,
): AddDishWithNewSource => {
  const normalizedInput = _.cloneDeep(input);
  const { dishSource } = input;

  normalizedInput.dishSourceRelationDetail = normalizeDishSourceRelationDetail(
    dishSource.type,
    normalizedInput.dishSourceRelation.dishSourceRelationDetail,
  );
  return normalizedInput;
};

export type AddDishInput = AddDish | AddDishWithNewSource;
export type AddDishOutput = AddDishMutation | AddDishWithNewSourceMutation;
export type AddDishFunc = (
  input: AddDishInput,
  mutationCallbacks: MutationCallbacks<AddDishOutput>,
) => void;

export const useAddDish = () => {
  const [addDish, addDishLoading, addDishError] = buildMutationExecutor<
    AddDish,
    AddDishMutation
  >(useAddDishMutation, {
    normalizeInput: convertFromAddDishInputToGraphqlInput,
  });

  const [
    addDishWithNewSource,
    addDishWithNewSourceLoading,
    addDishWithNewSourceError,
  ] = buildMutationExecutor<AddDishWithNewSource, AddDishWithNewSourceMutation>(
    useAddDishWithNewSourceMutation,
    { normalizeInput: convertFromAddDishWithNewSourceInputToGraphqlInput },
  );

  return {
    addDish,
    AddDishSchema,

    addDishWithNewSource,
    AddDishWithNewSourceSchema,

    addDishLoading: addDishLoading || addDishWithNewSourceLoading,
    addDishError: addDishError || addDishWithNewSourceError,
  };
};
