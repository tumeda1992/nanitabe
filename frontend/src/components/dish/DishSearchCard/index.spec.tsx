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
