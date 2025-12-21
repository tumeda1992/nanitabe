import * as z from 'zod';
import { MEAL_TYPE } from './const';

const dateSchema = z.date({
  required_error: '必須項目です。',
});

const mealTypeSchema = z.nativeEnum(MEAL_TYPE, {
  required_error: '必須項目です。',
});

const commentSchema = z.string().optional();

export const mealIdSchema = z.number();

export const newMealSchema = z.object({
  date: dateSchema,
  mealType: mealTypeSchema,
  comment: commentSchema,
});

export const updateMealSchema = z.object({
  id: mealIdSchema,
  date: dateSchema,
  mealType: mealTypeSchema,
  comment: commentSchema,
});
