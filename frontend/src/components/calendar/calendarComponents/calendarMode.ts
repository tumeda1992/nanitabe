export const DISPLAY_CALENDAR_MODE = 'DISPLAY_CALENDAR_MODE';

export const ASSIGNING_DISH_MODES = {
  CHOOSING_DISH_MODE: 'CHOOSING_DISH_MODE',
  ASSIGNING_SELECTED_DISH_MODE: 'ASSIGNING_SELECTED_DISH_MODE',
} as const;
export type AssigningDishMode =
  (typeof ASSIGNING_DISH_MODES)[keyof typeof ASSIGNING_DISH_MODES];

export const MOVING_MEAL_MODES = {
  MOVING_MEAL_MODE: 'MOVING_MEAL_MODE',
} as const;
export type MovingMealMode =
  (typeof MOVING_MEAL_MODES)[keyof typeof MOVING_MEAL_MODES];

export const SWAPPING_MEALS_MODES = {
  SWAPPING_MEALS_MODE: 'SWAPPING_MEALS_MODE',
} as const;
export type SwappingMealMode =
  (typeof SWAPPING_MEALS_MODES)[keyof typeof SWAPPING_MEALS_MODES];

export const POSTPONED_MEAL_MODES = {
  CHOOSING_POSTPONED_MEAL_MODE: 'CHOOSING_POSTPONED_MEAL_MODE',
  SCHEDULING_POSTPONED_MEAL_MODE: 'SCHEDULING_POSTPONED_MEAL_MODE',
} as const;
export type PostponedMealMode =
  (typeof POSTPONED_MEAL_MODES)[keyof typeof POSTPONED_MEAL_MODES];

export type CalendarMode =
  | typeof DISPLAY_CALENDAR_MODE
  | AssigningDishMode
  | MovingMealMode
  | SwappingMealMode
  | PostponedMealMode;

export type CalendarModeControls = {
  calendarMode: CalendarMode;
  updateCalendarMode: (mode: CalendarMode) => void;
  changeCalendarModeToDisplayCalendarMode: () => void;
  onDataChanged?: () => void | Promise<void>;
};
