export const MEAL_POSITION = {
  STAPLE_FOOD: 1,
  MAIN_DISH: 2,
  SIDE_DISH: 3,
  SOUP: 4,
  DESSERT: 5,
  OTHER: 50,
} as const;

export type MealPosition = (typeof MEAL_POSITION)[keyof typeof MEAL_POSITION];

export const MEAL_POSITIONS = Object.keys(MEAL_POSITION).map(
  (key) => MEAL_POSITION[key],
);

export const MEAL_POSITION_LABELS = {
  [MEAL_POSITION.STAPLE_FOOD]: '主食・炭水化物',
  [MEAL_POSITION.MAIN_DISH]: 'メインディッシュおかず',
  [MEAL_POSITION.SIDE_DISH]: '副菜・前菜',
  [MEAL_POSITION.SOUP]: '汁物',
  [MEAL_POSITION.DESSERT]: 'デザート',
  [MEAL_POSITION.OTHER]: 'その他',
};
