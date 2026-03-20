import React from 'react';
import '@testing-library/jest-dom';
import { render, screen } from '@testing-library/react';
import DishSearchCard from './index';
import Library from './Library';
import Picker from './Picker';

const baseDish = {
  id: 1,
  name: 'ハンバーグ',
  mealPosition: 2,
  comment: null,
  dishSourceName: null,
  evaluationScore: null,
  mealsCount: null,
  lastCookedDate: null,
};

describe('<DishSearchCard>', () => {
  describe('when rendering base card', () => {
    it('shows dish name', () => {
      render(<DishSearchCard dish={baseDish} />);
      expect(screen.getByText('ハンバーグ')).toBeInTheDocument();
    });

    it('shows evaluationScore when provided', () => {
      const dish = { ...baseDish, evaluationScore: 4 };
      render(<DishSearchCard dish={dish} />);
      expect(screen.getByText('★4')).toBeInTheDocument();
    });

    it('shows dishSourceName when provided', () => {
      const dish = { ...baseDish, dishSourceName: 'りゅうじ' };
      render(<DishSearchCard dish={dish} />);
      expect(screen.getByText('りゅうじ')).toBeInTheDocument();
    });

    it('shows trailing slot when provided', () => {
      render(
        <DishSearchCard
          dish={baseDish}
          trailing={<span data-testid="trailing-slot">trailing</span>}
        />,
      );
      expect(screen.getByTestId('trailing-slot')).toBeInTheDocument();
    });

    describe('effortLevelMinutes', () => {
      it('shows effort time when effortLevelMinutes is provided (under 60 min)', () => {
        const dish = { ...baseDish, effortLevelMinutes: 20 };
        render(<DishSearchCard dish={dish} />);
        expect(screen.getByText('🕐 20分')).toBeInTheDocument();
      });

      it('shows effort time when effortLevelMinutes is 60 min or more', () => {
        const dish = { ...baseDish, effortLevelMinutes: 90 };
        render(<DishSearchCard dish={dish} />);
        expect(screen.getByText('🕐 1時間30分')).toBeInTheDocument();
      });

      it('does not show effort time when effortLevelMinutes is null', () => {
        const dish = { ...baseDish, effortLevelMinutes: null };
        render(<DishSearchCard dish={dish} />);
        expect(screen.queryByText(/🕐/)).not.toBeInTheDocument();
      });

      it('does not show effort time when effortLevelMinutes is undefined', () => {
        render(<DishSearchCard dish={baseDish} />);
        expect(screen.queryByText(/🕐/)).not.toBeInTheDocument();
      });
    });

    it('shows last cooked date and meals count when provided', () => {
      const dish = { ...baseDish, mealsCount: 3, lastCookedDate: '2024-03-20' };
      render(<DishSearchCard dish={dish} />);
      expect(screen.getByText('最終 2024/3/20')).toBeInTheDocument();
      expect(screen.getByText('3回')).toBeInTheDocument();
    });

    it('shows 未調理 and 0回 when lastCookedDate is null', () => {
      const dish = { ...baseDish, mealsCount: 0, lastCookedDate: null };
      render(<DishSearchCard dish={dish} />);
      expect(screen.getByText('未調理')).toBeInTheDocument();
      expect(screen.getByText('0回')).toBeInTheDocument();
    });

    it('shows 0回 when mealsCount is 0', () => {
      const dish = { ...baseDish, mealsCount: 0, lastCookedDate: null };
      render(<DishSearchCard dish={dish} />);
      expect(screen.getByText('0回')).toBeInTheDocument();
    });
  });
});

describe('<Library>', () => {
  it('shows ... menu when onEdit and onDelete are provided', () => {
    render(
      <Library
        dish={baseDish}
        onEdit={() => {}}
        onDelete={() => {}}
      />,
    );
    expect(screen.getByLabelText('操作メニュー')).toBeInTheDocument();
  });

  it('does not show ... menu when both onEdit and onDelete are undefined', () => {
    render(
      <Library
        dish={baseDish}
      />,
    );
    expect(screen.queryByLabelText('操作メニュー')).not.toBeInTheDocument();
  });
});

describe('<Picker>', () => {
  it('shows checkmark when selected=true', () => {
    render(
      <Picker
        dish={baseDish}
        selected={true}
        onToggle={() => {}}
      />,
    );
    // selected=true のとき bg-primary クラスを持つ要素が存在する
    const checkmark = document.querySelector('.bg-primary');
    expect(checkmark).toBeInTheDocument();
  });
});
