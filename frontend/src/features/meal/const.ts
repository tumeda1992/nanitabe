export const MEAL_TYPE = {
  BREAKFAST: 1,
  LUNCH: 2,
  DINNER: 3,
} as const;

export type MealType = (typeof MEAL_TYPE)[keyof typeof MEAL_TYPE];

export const MEAL_TYPES = Object.keys(MEAL_TYPE).map((key) => MEAL_TYPE[key]);

export const MEAL_TYPE_LABELS = {
  [MEAL_TYPE.BREAKFAST]: '朝食',
  [MEAL_TYPE.LUNCH]: '昼食',
  [MEAL_TYPE.DINNER]: '夕食',
};
