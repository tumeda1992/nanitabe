import { useAddDish } from './addDishMutation';
import { useUpdateDish } from './updateDishMutation';
import { useAddMeal } from '../meal/addMealMutation';
import { useUpdateMeal } from '../meal/updateMealMutation';
import { DISH_SOURCE_TYPE } from './source/const';

const mockNormalizers: ((input: any) => any)[] = [];
jest.mock('../utils/mutationUtils', () => ({
  buildMutationExecutor: (_hook, options) => {
    mockNormalizers.push(options?.normalizeInput);
    return [jest.fn(), false, undefined];
  },
}));

const freezeDeep = (value) => {
  if (value && typeof value === 'object') {
    Object.values(value).forEach(freezeDeep);
    Object.freeze(value);
  }
  return value;
};

const input = () => ({
  dish: { name: '料理', mealPosition: 1 },
  meal: { id: 9, date: new Date('2026-10-26T09:00:00'), mealType: 3 },
  frameEntryId: 17,
  dishTags: [{ content: '保存するタグ' }],
  selectedDishSource: { id: 4, type: DISH_SOURCE_TYPE.RECIPE_BOOK },
  dishSource: { name: '新しい本', type: DISH_SOURCE_TYPE.RECIPE_BOOK },
  dishSourceRelation: {
    dishSourceRelationDetail: {
      detailType: 'recipeBookPage',
      recipeBookPage: 12,
    },
  },
});

beforeEach(() => {
  mockNormalizers.length = 0;
});

it.each([useAddDish, useAddMeal, useUpdateMeal])(
  'preserves payload and input for existing-source callers',
  (hook) => {
    hook();
    const normalize = mockNormalizers.find(Boolean)!;
    const original = freezeDeep(input());
    const converted = normalize(original);
    expect(converted).toEqual({
      ...original,
      dishSource: original.selectedDishSource,
      dishSourceRelationDetail: { recipeBookPage: 12 },
    });
    expect(converted.meal).not.toBe(original.meal);
    expect(
      original.dishSourceRelation.dishSourceRelationDetail.detailType,
    ).toBe('recipeBookPage');
    const withoutSource = {
      ...input(),
      selectedDishSource: { id: null, type: null },
    };
    expect(normalize(withoutSource)).toMatchObject({
      dishSource: null,
      dishSourceRelationDetail: null,
    });
  },
);

it.each([useAddDish, useUpdateDish, useAddMeal, useUpdateMeal])(
  'preserves payload and input for new-source callers',
  (hook) => {
    hook();
    const normalize = mockNormalizers.filter(Boolean)[1];
    const original = freezeDeep(input());
    expect(normalize(original)).toEqual({
      ...original,
      dishSourceRelationDetail: { recipeBookPage: 12 },
    });
    expect(
      original.dishSourceRelation.dishSourceRelationDetail.detailType,
    ).toBe('recipeBookPage');
  },
);
