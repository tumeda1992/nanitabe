import React from 'react';
import { act, fireEvent, render, screen } from '@testing-library/react';
import useDish from '../../../features/dish/useDish';
import DishSearchPanel from './index';

jest.mock('../../../features/dish/useDish', () => ({
  __esModule: true,
  default: jest.fn(() => ({ existingDishesForRegisteringWithMeal: [], fetchLoading: false })),
}));
beforeEach(() => { jest.useFakeTimers(); jest.clearAllMocks(); });
afterEach(() => { jest.clearAllTimers(); jest.useRealTimers(); });

it('keeps debounce timers independent between panels', () => {
  const first = jest.fn();
  const second = jest.fn();
  render(<>
    <DishSearchPanel renderCard={() => null} dishIdRegisteredWithMeal={101} onSearchStringChange={first} />
    <DishSearchPanel renderCard={() => null} dishIdRegisteredWithMeal={102} onSearchStringChange={second} />
  </>);
  const inputs = screen.getAllByPlaceholderText('料理を検索できます');
  fireEvent.change(inputs[0], { target: { value: 'alpha' } });
  act(() => { jest.advanceTimersByTime(200); });
  fireEvent.change(inputs[1], { target: { value: 'beta' } });
  act(() => { jest.advanceTimersByTime(200); });
  expect(first).toHaveBeenCalledWith('alpha');
  expect(second).not.toHaveBeenCalled();
  act(() => { jest.advanceTimersByTime(200); });
  expect(second).toHaveBeenCalledWith('beta');
  const searches = (useDish as jest.Mock).mock.calls.map(([args]) => args.fetchDishesParams.fetchExistingDishesForRegisteringWithMealParams);
  expect(searches).toEqual(expect.arrayContaining([
    expect.objectContaining({ dishIdRegisteredWithMeal: 101, searchString: 'alpha' }),
    expect.objectContaining({ dishIdRegisteredWithMeal: 102, searchString: 'beta' }),
  ]));
});

it('submits only the latest text after exactly 400 milliseconds', () => {
  const changed = jest.fn();
  render(<DishSearchPanel renderCard={() => null} onSearchStringChange={changed} />);
  const input = screen.getByPlaceholderText('料理を検索できます');
  fireEvent.change(input, { target: { value: 'old' } });
  act(() => { jest.advanceTimersByTime(200); });
  fireEvent.change(input, { target: { value: 'latest' } });
  act(() => { jest.advanceTimersByTime(399); });
  expect(changed).not.toHaveBeenCalled();
  act(() => { jest.advanceTimersByTime(1); });
  expect(changed).toHaveBeenCalledTimes(1);
  expect(changed).toHaveBeenCalledWith('latest');
});

it('cancels pending search callbacks when the panel unmounts', () => {
  const changed = jest.fn();
  const view = render(<DishSearchPanel renderCard={() => null} onSearchStringChange={changed} />);
  fireEvent.change(screen.getByPlaceholderText('料理を検索できます'), { target: { value: 'cancelled' } });
  view.unmount();
  act(() => { jest.advanceTimersByTime(400); });
  expect(changed).not.toHaveBeenCalled();
});
