import React from 'react';
import '@testing-library/jest-dom';
import { render } from '@testing-library/react';
import CategoryIcon from './CategoryIcon';

describe('<CategoryIcon>', () => {
  it('内側の span が svg を block で枠いっぱいに置く指定を持つこと', () => {
    const { container } = render(<CategoryIcon mealPosition={2} />);
    const svg = container.querySelector('svg') as SVGElement;
    const inner = svg.parentElement as HTMLElement;
    expect(inner).toHaveClass('[&>svg]:block');
    expect(inner).toHaveClass('[&>svg]:size-full');
  });
});
