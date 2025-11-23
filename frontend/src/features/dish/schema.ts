import * as z from 'zod';
import { MEAL_POSITION } from './const';
import {
  dishSourceIdSchema,
  dishSourceTypeOptionalSchema,
} from './source/schema';
import { DISH_SOURCE_TYPE } from './source/const';

export const dishIdSchema = z.number();

const buildDishSchema = () => {
  const nameSchema = z.string().min(1, { message: '必須項目です。' });

  const mealPositionSchema = z.nativeEnum(MEAL_POSITION, {
    required_error: '必須項目です。',
  });

  const commentSchema = z.string().optional();

  const newDishSchema = z.object({
    name: nameSchema,
    mealPosition: mealPositionSchema,
    comment: commentSchema,
  });

  const updateDishSchema = z.object({
    id: dishIdSchema,
    name: nameSchema,
    mealPosition: mealPositionSchema,
    comment: commentSchema,
  });

  return { newDishSchema, updateDishSchema };
};

export const { newDishSchema, updateDishSchema } = buildDishSchema();

export const selectExistingDishSourceSchema = z
  .object({
    id: dishSourceIdSchema.nullish(),
    type: dishSourceTypeOptionalSchema,
  })
  .optional();

export const DISH_SOURCE_RELATION_DETAIL_VALUE_TYPE = {
  RECIPE_BOOK_PAGE: 'recipeBookPage',
  RECIPE_WEBSITE_URL: 'recipeWebsiteUrl',
  RECIPE_SOURCE_MEMO: 'recipeSourceMemo',
  NO_VALUE: 'noValue',
} as const;

export const dishSourceRelationDetailOf = (dishSourceType) => {
  switch (dishSourceType) {
    case DISH_SOURCE_TYPE.RECIPE_BOOK:
      return DISH_SOURCE_RELATION_DETAIL_VALUE_TYPE.RECIPE_BOOK_PAGE;
    case DISH_SOURCE_TYPE.YOUTUBE:
    case DISH_SOURCE_TYPE.WEBSITE:
      return DISH_SOURCE_RELATION_DETAIL_VALUE_TYPE.RECIPE_WEBSITE_URL;
    case DISH_SOURCE_TYPE.RESTAURANT:
    case DISH_SOURCE_TYPE.OTHER:
      return DISH_SOURCE_RELATION_DETAIL_VALUE_TYPE.RECIPE_SOURCE_MEMO;
    default:
      return DISH_SOURCE_RELATION_DETAIL_VALUE_TYPE.NO_VALUE;
  }
};

const buildDishSourceRelationSchema = () => {
  const recipeBookPageSchema = z.number().nullish();
  const recipeWebsiteUrlSchema = z.string().nullish();
  const recipeSourceMemoSchema = z.string().nullish();

  /*
   * NOTE:
   * 始めはunionやdiscriminatedUnionを使って
   * detailTypeに合わせたフィールドしかいじれない型を提供しようとしたが頓挫。
   * (頓挫理由: detailTypeをhiddenで持っていたが、表示するhiddenを切り替えたのにdetailTypeが切り替わってくれなかった)
   * 今更detailTypeもGraphQLInputへの変換時の判断にしか使っていないし、実質sourceTypeに置き換えられるけど、
   * detailTypeの値を元にtransformして使う値だけに変換するなら残してもいい
   */
  const dishSourceRelationDetailSchema = z.object({
    detailType: z.nativeEnum(DISH_SOURCE_RELATION_DETAIL_VALUE_TYPE),
    recipeBookPage: recipeBookPageSchema,
    recipeWebsiteUrl: recipeWebsiteUrlSchema,
    recipeSourceMemo: recipeSourceMemoSchema,
  });

  // NOTE: putと銘打っているのはaddもupdateも区別したくないと思っているからだが、多分これはupdateフレンドリーでaddでは別の値必要になりそう
  const putDishRelationSchema = z.object({
    dishSourceRelationDetail: dishSourceRelationDetailSchema,
  });

  return { putDishRelationSchema };
};

export const { putDishRelationSchema } = buildDishSourceRelationSchema();

export const dishTagsSchema = z.object({
  id: z.number().nullish(),
  content: z.string().min(1, { message: '空では登録できません。' }),
}).array();
