export const DISH_SOURCE_TYPE = {
  RECIPE_BOOK: 1,
  YOUTUBE: 2,
  WEBSITE: 3,
  RESTAURANT: 4,
  OTHER: 50,
} as const;

export type DishSourceType =
  (typeof DISH_SOURCE_TYPE)[keyof typeof DISH_SOURCE_TYPE];

export const DISH_SOURCE_TYPES = Object.keys(DISH_SOURCE_TYPE).map(
  (key) => DISH_SOURCE_TYPE[key],
);

export const DISH_SOURCE_TYPE_LABELS = {
  [DISH_SOURCE_TYPE.RECIPE_BOOK]: 'レシピ本',
  [DISH_SOURCE_TYPE.YOUTUBE]: 'Youtube動画',
  [DISH_SOURCE_TYPE.WEBSITE]: 'Webサイト',
  [DISH_SOURCE_TYPE.RESTAURANT]: '外食',
  [DISH_SOURCE_TYPE.OTHER]: 'その他',
};
