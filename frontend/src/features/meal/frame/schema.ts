import * as z from 'zod';

export const mealFrameNameSchema = z
  .string({
    required_error: '必須項目です。',
  })
  .min(1, '枠名を入力してください。');

export const mealFrameIdSchema = z.number();

export const newMealFrameSchema = z.object({
  name: mealFrameNameSchema,
});

export type NewMealFrame = z.infer<typeof newMealFrameSchema>;
