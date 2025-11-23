import React from 'react';
import classnames from 'classnames';
import style from './ExistingDishIconForDisplay.module.scss';

type Props = {
  dish: any;
};

export default (props: Props) => {
  const { dish } = props;
  return (
    <div
      className={classnames(style['icon'], style['existing-dish-icon'])}
      data-testid={`existingDish-${dish.id}`}
    >
      {dish.name}
    </div>
  );
};
