import React from 'react';
import { render } from '@testing-library/react';
import Calendar from './index';

let mockControls: any;
const mockRefreshData = jest.fn();
jest.mock('../../useRefreshCalendarData', () => ({
  __esModule: true,
  default: () => ({ refreshData: mockRefreshData }),
}));
jest.mock('../useCalendarMode', () => ({
  __esModule: true,
  default: (args: any) => {
    mockControls = args;
    return {
      isDisplayCalendarMode: true,
      useAssignDishModeResult: {}, calendarModeChangers: {},
      useMoveMealModeResult: {}, useSwapMealsModeResult: {}, usePostponedMealModeResult: {},
      requireDisplayingBottomBar: false, onDateClick: jest.fn(),
    };
  },
}));

it('passes the pending refresh promise through the calendar mode boundary', () => {
  const pending = new Promise<void>(() => {});
  mockRefreshData.mockReturnValue(pending);
  render(<Calendar dateMealsList={[]} fetchMealsLoading={false} refetchMealsForCalendar={jest.fn()} refreshToPrev={jest.fn()} refreshToNext={jest.fn()}>{() => null}</Calendar>);
  expect(mockControls.onDataChanged()).toBe(pending);
});
