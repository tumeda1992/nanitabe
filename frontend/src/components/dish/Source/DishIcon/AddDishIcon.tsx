import React from 'react';
import Link from 'next/link';
import classnames from 'classnames';
import style from './AddDishIcon.module.scss';

export default (props: { addDishParams?: any }) => {
  const { addDishParams = {} } = props;
  return (
    <Link
      href={{
        pathname: '/dishes/new',
        query: addDishParams,
      }}
    >
      <div className={classnames(style['icon'], style['add-meal-icon'])}>
        <div className={style['add-dish-icon__content']}>+</div>
      </div>
    </Link>
  );
};
