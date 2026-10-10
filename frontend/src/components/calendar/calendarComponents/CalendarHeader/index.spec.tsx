import React from 'react';
import '@testing-library/jest-dom';
import { screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import CalendarHeader from './index';
import renderWithApollo from '../../../specHelper/renderWithApollo';

describe('<CalendarHeader>', () => {
  const baseProps = {
    viewType: 'week' as const,
    displayLabel: '2026年3月7日〜13日',
    currentDate: new Date(2026, 2, 7),
    refreshToPrev: jest.fn(),
    refreshToNext: jest.fn(),
    isDisplayCalendarMode: true,
    onStartAssigningDish: jest.fn(),
    onStartPostponedMeal: jest.fn(),
  };

  describe('when viewType is week', () => {
    beforeEach(() => {
      renderWithApollo(<CalendarHeader {...baseProps} />);
    });

    it('displays the period label', () => {
      expect(screen.getByText('2026年3月7日〜13日')).toBeInTheDocument();
    });

    it('displays navigation buttons', () => {
      expect(screen.getByLabelText('前の週')).toBeInTheDocument();
      expect(screen.getByLabelText('次の週')).toBeInTheDocument();
    });

    it('displays today button as 今週', () => {
      expect(screen.getByText('今週')).toBeInTheDocument();
    });

    it('displays week/month view toggle buttons', () => {
      expect(screen.getByLabelText('週間ビュー')).toBeInTheDocument();
      expect(screen.getByLabelText('月間ビュー')).toBeInTheDocument();
    });

    it('displays dropdown menu trigger', () => {
      expect(screen.getByLabelText('メニュー')).toBeInTheDocument();
    });
  });

  describe('when viewType is month', () => {
    beforeEach(() => {
      renderWithApollo(
        <CalendarHeader
          {...baseProps}
          viewType="month"
          displayLabel="2026年3月"
        />,
      );
    });

    it('displays today button as 今月', () => {
      expect(screen.getByText('今月')).toBeInTheDocument();
    });

    it('displays navigation buttons for month', () => {
      expect(screen.getByLabelText('前の月')).toBeInTheDocument();
      expect(screen.getByLabelText('次の月')).toBeInTheDocument();
    });
  });

  describe('when isDisplayCalendarMode is false', () => {
    it('does not show 食事割当て in dropdown', () => {
      renderWithApollo(
        <CalendarHeader {...baseProps} isDisplayCalendarMode={false} />,
      );
      // ドロップダウンは開いていないので食事割当てテキストは表示されない
      expect(screen.queryByText('食事割当て')).not.toBeInTheDocument();
    });
  });

  describe('延期した食事メニュー', () => {
    it('メニューを開くと「延期した食事」が表示され、タップで onStartPostponedMeal が呼ばれること', async () => {
      const onStartPostponedMeal = jest.fn();
      renderWithApollo(
        <CalendarHeader {...baseProps} onStartPostponedMeal={onStartPostponedMeal} />,
      );

      await userEvent.click(screen.getByLabelText('メニュー'));
      const menuItem = await screen.findByText('延期した食事');
      await userEvent.click(menuItem);

      expect(onStartPostponedMeal).toHaveBeenCalled();
    });
  });
});
