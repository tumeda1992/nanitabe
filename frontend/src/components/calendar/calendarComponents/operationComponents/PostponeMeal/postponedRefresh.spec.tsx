import React from 'react';
import '@testing-library/jest-dom';
import { act, fireEvent, render, renderHook, screen } from '@testing-library/react';
import usePostponedMeal from '../../../../../features/meal/postponed/usePostponedMeal';
import usePostponedMealMode, { POSTPONED_MEAL_MODES } from './usePostponedMealMode';
import ScheduleHeader from './ScheduleChosenPostponedMealForDate';

jest.mock('../../../../../features/meal/postponed/usePostponedMeal', () => ({ __esModule: true, default: jest.fn() }));
const deferred = () => {
  let resolve!: () => void;
  const promise = new Promise<void>((yes) => { resolve = yes; });
  return { promise, resolve };
};
const selected = { id: 3, dishName: 'test dish' };
const setup = (refresh: () => Promise<void>, refetch: () => Promise<void>) => {
  const schedule = jest.fn().mockResolvedValue({});
  (usePostponedMeal as jest.Mock).mockReturnValue({ schedulePostponedMeal: schedule, refetchPostponedMeals: refetch });
  const display = jest.fn();
  const hook = renderHook(() => usePostponedMealMode({
    calendarMode: POSTPONED_MEAL_MODES.SCHEDULING_POSTPONED_MEAL_MODE,
    updateCalendarMode: jest.fn(), changeCalendarModeToDisplayCalendarMode: display, onDataChanged: refresh,
  }));
  act(() => hook.result.current.selectPostponedMeal(selected));
  act(() => hook.result.current.onDateClickForSchedulingPostponedMeal(new Date(2026, 0, 1)));
  return { ...hook, display, schedule, complete: () => schedule.mock.calls[0][1].onCompleted() };
};

it('keeps selection and mode until both refresh stages finish', async () => {
  const calendar = deferred();
  const postponed = deferred();
  const refetch = jest.fn(() => postponed.promise);
  const hook = setup(() => calendar.promise, refetch);
  act(() => hook.result.current.onDateClickForSchedulingPostponedMeal(new Date(2026, 0, 2)));
  expect(hook.schedule).toHaveBeenCalledTimes(1);
  let completion: Promise<void>;
  act(() => { completion = hook.complete(); });
  expect(refetch).not.toHaveBeenCalled();
  expect(hook.display).not.toHaveBeenCalled();
  expect(hook.result.current.selectedPostponedMeal).toEqual(selected);
  await act(async () => { calendar.resolve(); });
  expect(refetch).toHaveBeenCalledTimes(1);
  expect(hook.display).not.toHaveBeenCalled();
  await act(async () => { postponed.resolve(); await completion; });
  expect(hook.display).toHaveBeenCalledTimes(1);
  expect(hook.result.current.selectedPostponedMeal).toBeNull();
});

it.each(['calendar', 'postponed'])('keeps the selection after %s refresh fails and can retry without registering twice', async (stage) => {
  const refresh = jest.fn().mockResolvedValue(undefined);
  const refetch = jest.fn().mockResolvedValue(undefined);
  (stage === 'calendar' ? refresh : refetch).mockRejectedValueOnce(new Error('refresh failed'));
  const hook = setup(refresh, refetch);
  await act(async () => { await hook.complete(); });
  expect(hook.display).not.toHaveBeenCalled();
  expect(hook.result.current.selectedPostponedMeal).toEqual(selected);
  expect(hook.result.current.refreshError).toBeTruthy();
  if (stage === 'calendar') expect(refetch).not.toHaveBeenCalled();
  act(() => hook.result.current.onDateClickForSchedulingPostponedMeal(new Date(2026, 0, 2)));
  expect(hook.schedule).toHaveBeenCalledTimes(1);
  await act(async () => { await hook.result.current.retryRefresh(); });
  expect(hook.display).toHaveBeenCalledTimes(1);
  expect(hook.result.current.selectedPostponedMeal).toBeNull();
  expect(hook.schedule).toHaveBeenCalledTimes(1);
});

it('shows a refresh failure and a retry control', () => {
  const retry = jest.fn();
  render(<ScheduleHeader usePostponedMealModeResult={{
    selectedPostponedMeal: selected, refreshError: '表示の更新に失敗しました',
    retryRefresh: retry, isScheduling: false,
    changeCalendarModeToDisplayCalendarMode: jest.fn(), changeCalendarModeToChoosingPostponedMealMode: jest.fn(),
  }} />);
  expect(screen.getByRole('alert')).toHaveTextContent('表示の更新に失敗しました');
  fireEvent.click(screen.getByRole('button', { name: '表示を再取得' }));
  expect(retry).toHaveBeenCalledTimes(1);
});

it('keeps selection and releases the busy state when registration fails', () => {
  const hook = setup(jest.fn().mockResolvedValue(undefined), jest.fn().mockResolvedValue(undefined));
  act(() => hook.schedule.mock.calls[0][1].onError(new Error('registration failed')));
  expect(hook.result.current.selectedPostponedMeal).toEqual(selected);
  expect(hook.result.current.scheduleError).toBeTruthy();
  expect(hook.result.current.isScheduling).toBe(false);
  expect(hook.display).not.toHaveBeenCalled();
  act(() => hook.result.current.onDateClickForSchedulingPostponedMeal(new Date(2026, 0, 2)));
  expect(hook.schedule).toHaveBeenCalledTimes(2);
});
