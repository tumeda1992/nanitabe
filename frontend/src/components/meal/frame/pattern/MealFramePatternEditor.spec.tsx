import React from 'react';
import '@testing-library/jest-dom';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import MealFramePatternForm from './MealFramePatternForm';
import MealFramePatternEditForm from './MealFramePatternEditForm';

const mockSubmit = jest.fn(async (_input, callbacks) => {
  callbacks.onCompleted();
});
jest.mock(
  '../../../../features/meal/frame/pattern/useMealFramePattern',
  () => ({
    __esModule: true,
    default: () => ({ addMealFramePattern: mockSubmit }),
  }),
);
jest.mock('../../../../features/meal/frame/useMealFrame', () => ({
  __esModule: true,
  default: () => ({
    mealFrames: [
      { id: 1, name: '朝枠' },
      { id: 2, name: '夜枠' },
    ],
  }),
}));

const entries = [
  { dayOffset: 1, mealType: 1, mealFrameId: 1 },
  { dayOffset: 3, mealType: 3, mealFrameId: 2 },
];

beforeEach(() => mockSubmit.mockClear());

describe.each(['create', 'edit'])('%s pattern editor', (mode) => {
  const renderForm = (name = '元のパターン') => {
    const onSubmitSucceeded = jest.fn();
    render(
      mode === 'create' ? (
        <MealFramePatternForm
          onSubmitSucceeded={onSubmitSucceeded}
          defaultName={name}
          defaultDaySlots={[
            { entries: [entries[0]] },
            { entries: [] },
            { entries: [entries[1]] },
          ]}
        />
      ) : (
        <MealFramePatternEditForm
          pattern={{ id: 8, name, entries }}
          updateMealFramePattern={mockSubmit}
          onSubmitSucceeded={onSubmitSucceeded}
        />
      ),
    );
    return onSubmitSucceeded;
  };

  it('restores values, edits and renumbers days, then sends the payload and completes', async () => {
    const user = userEvent.setup();
    const succeeded = renderForm();
    expect(screen.getByTestId('mealFramePatternName')).toHaveValue(
      '元のパターン',
    );
    expect(screen.getByTestId('mealType-0-0')).toHaveValue('1');
    expect(screen.getByTestId('mealFrame-2-0')).toHaveValue('2');
    await user.click(screen.getByTestId('removeDaySlot-0'));
    await user.selectOptions(screen.getByTestId('mealType-1-0'), '2');
    await user.selectOptions(screen.getByTestId('mealFrame-1-0'), '1');
    await user.click(screen.getByTestId('addDaySlotButton'));
    await user.click(screen.getByTestId('addEntryToDay-2'));
    await user.click(screen.getByTestId('removeEntry-2-0'));
    await user.click(screen.getByTestId('submitMealFramePatternButton'));
    expect(mockSubmit.mock.calls[0][0]).toEqual({
      mealFramePattern: {
        ...(mode === 'edit' ? { id: 8 } : {}),
        name: '元のパターン',
        entries: [{ dayOffset: 2, mealType: 2, mealFrameId: 1 }],
      },
    });
    expect(succeeded).toHaveBeenCalledTimes(1);
  });

  it('rejects a blank name', async () => {
    const user = userEvent.setup();
    renderForm('  ');
    await user.click(screen.getByTestId('submitMealFramePatternButton'));
    expect(
      screen.getByText('パターン名を入力してください。'),
    ).toBeInTheDocument();
    expect(mockSubmit).not.toHaveBeenCalled();
  });

  it('rejects an unselected frame and clears its error after selection', async () => {
    const user = userEvent.setup();
    renderForm();
    await user.click(screen.getByTestId('addEntryToDay-1'));
    await user.click(screen.getByTestId('submitMealFramePatternButton'));
    expect(
      screen.getByTestId('mealFramePatternEntryError'),
    ).toBeInTheDocument();
    expect(mockSubmit).not.toHaveBeenCalled();
    await user.selectOptions(screen.getByTestId('mealFrame-1-0'), '2');
    await user.click(screen.getByTestId('submitMealFramePatternButton'));
    expect(
      screen.queryByTestId('mealFramePatternEntryError'),
    ).not.toBeInTheDocument();
    expect(mockSubmit).toHaveBeenCalledTimes(1);
  });
});
