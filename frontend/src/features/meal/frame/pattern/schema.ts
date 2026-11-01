import * as z from 'zod';

export const mealFramePatternEntrySchema = z.object({
  dayOffset: z.number().min(1, '日数は1以上で指定してください。'),
  mealType: z.number(),
  mealFrameId: z.number(),
});

export const mealFramePatternSchema = z.object({
  name: z
    .string({
      required_error: '必須項目です。',
    })
    .min(1, 'パターン名を入力してください。'),
  entries: z.array(mealFramePatternEntrySchema),
});

export const addMealFramePatternSchema = z.object({
  mealFramePattern: mealFramePatternSchema,
});

export const updateMealFramePatternSchema = z.object({
  mealFramePattern: z.object({ id: z.number() }).merge(mealFramePatternSchema),
});
