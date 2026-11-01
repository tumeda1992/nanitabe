import { act, renderHook } from '@testing-library/react';
import useCalendarMode from './useCalendarMode';

const mockSwapMealsBetweenDays = jest.fn();

jest.mock('../../../features/meal/useMeal', () => ({
  __esModule: true,
  default: () => ({
    addMeal: jest.fn(),
    updateMeal: jest.fn(),
    swapMealsBetweenDays: mockSwapMealsBetweenDays,
  }),
}));
jest.mock('../../../features/dish/useDish', () => ({
  __esModule: true,
  default: () => ({}),
}));
jest.mock('../../../features/meal/postponed/usePostponedMeal', () => ({
  __esModule: true,
  default: () => ({ refetchPostponedMeals: jest.fn() }),
}));
jest.mock('../../../app/logical-history', () => ({
  useLogicalHistory: () => ({
    currentPathAndQuery: '/calendar/week',
    pushHistory: jest.fn(),
  }),
}));

it('starts in display mode and returns there on Escape after choosing a dish', () => {
  const { result } = renderHook(() =>
    useCalendarMode({ onDataChanged: jest.fn() }),
  );
  expect(result.current.isDisplayCalendarMode).toBe(true);
  act(() => result.current.useAssignDishModeResult.startAssigningDishMode());
  expect(result.current.useAssignDishModeResult.isChoosingDishMode).toBe(true);
  expect(result.current.requireDisplayingBottomBar).toBe(true);
  act(() =>
    document.dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape' })),
  );
  expect(result.current.isDisplayCalendarMode).toBe(true);
});

it('switches from postponed meal selection to scheduling and back to display', () => {
  const { result } = renderHook(() =>
    useCalendarMode({ onDataChanged: jest.fn() }),
  );
  act(() => result.current.usePostponedMealModeResult.startPostponedMealMode());
  expect(
    result.current.usePostponedMealModeResult.isChoosingPostponedMealMode,
  ).toBe(true);
  act(() =>
    result.current.usePostponedMealModeResult.selectPostponedMeal({ id: 3 }),
  );
  expect(
    result.current.usePostponedMealModeResult.isSchedulingPostponedMealMode,
  ).toBe(true);
  act(() =>
    result.current.usePostponedMealModeResult.changeCalendarModeToDisplayCalendarMode(),
  );
  expect(result.current.isDisplayCalendarMode).toBe(true);
});

// Compile-time contract: misspelled modes must be rejected.
function assertCalendarModeTypes(
  update: import('./calendarMode').CalendarModeControls['updateCalendarMode'],
) {
  update('DISPLAY_CALENDAR_MODE');
  // @ts-expect-error Unknown mode must not widen to string.
  update('DISPLAY_CALENDAR_MOD');
}

it('does not send a swap before a starting date has been chosen', () => {
  mockSwapMealsBetweenDays.mockClear();
  const { result } = renderHook(() => useCalendarMode({ onDataChanged: jest.fn() }));
  act(() => result.current.useSwapMealsModeResult.onDateClickForSwappingMeals(new Date(2026, 0, 2)));
  expect(mockSwapMealsBetweenDays).not.toHaveBeenCalled();
});

it('sends both selected dates after entering swap mode', () => {
  mockSwapMealsBetweenDays.mockClear();
  const first = new Date(2026, 0, 1);
  const second = new Date(2026, 0, 2);
  const { result } = renderHook(() => useCalendarMode({ onDataChanged: jest.fn() }));
  act(() => result.current.useSwapMealsModeResult.startSwappingMealsMode(first));
  act(() => result.current.useSwapMealsModeResult.onDateClickForSwappingMeals(second));
  expect(mockSwapMealsBetweenDays).toHaveBeenCalledWith({ date1: first, date2: second }, expect.any(Object));
});
