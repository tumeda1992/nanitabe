import React from 'react';
import Link from 'next/link';
import classnames from 'classnames';
import style from './index.module.scss';
import { DishWithRegisteredMeals } from '../../../../lib/graphql/generated/graphql';
import useDish from '../../../../features/dish/useDish';

type Props = {
  dish: DishWithRegisteredMeals;
  onChanged?: () => void;
};

export default (props: Props) => {
  const { dish, onChanged } = props;
  const { removeDish } = useDish();

  const handleRemoveDish = async (e) => {
    e.preventDefault();
    if (dish.meals.length > 0) {
      window.alert('この料理が登録されている食事があるので、削除できません');
      return;
    }

    const confirmed = window.confirm('本当に削除してもよろしいですか？');
    if (!confirmed) return;
    await removeDish(
      { dishId: dish.id },
      {
        onCompleted: (_) => {
          if (onChanged) onChanged();
        },
      },
    );
  };

  return (
    <div className={classnames(style['dish-icon__container'], style['icon'])}>
      <div className={style['dish-icon__content']}>
        <Link href={`/dishes/${dish.id}/edit`}>{dish.name}</Link>
        &nbsp;
        <a onClick={handleRemoveDish} data-testid="dishDeleteButton">
          ×
        </a>
      </div>
    </div>
  );
};
