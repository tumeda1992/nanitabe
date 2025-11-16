import React from 'react';
import AddMeal from '../../components/meal/MealForm/AddMeal';
import style from '../../components/meal/MealForm/MealForm.module.scss';

export const getServerSideProps = async () => {
  return { props: {} };
};

export default (props) => {
  return (
    <>
      <h1 className={style['form__title']}>食事登録</h1>
      <AddMeal />
    </>
  );
};
