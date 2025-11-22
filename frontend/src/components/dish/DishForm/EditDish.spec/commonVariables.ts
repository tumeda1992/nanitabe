import '@testing-library/jest-dom';
import {
  registerQueryHandler,
} from '../../../../lib/graphql/specHelper/mockServer';
import {
  DishSourcesDocument,
} from '../../../../lib/graphql/generated/graphql';
import { DISH_SOURCE_TYPE } from '../../../../features/dish/source/const';

export const registeredDish = {
  id: 55,
  name: '生姜焼き',
  mealPosition: 2,
};

export const updatedDish = {
  id: 55,
  name: '目玉焼き',
  mealPosition: 1,
  comment: null,
};

export const registeredDishSource = {
  id: 1,
  name: 'りゅうじ',
  type: DISH_SOURCE_TYPE.YOUTUBE,
};

export const registeredDishSource2 = {
  id: 2,
  name: 'アホアホチャンネル',
  type: DISH_SOURCE_TYPE.WEBSITE,
};

export const newDishSource = {
  name: '最強のレシピサイト',
  type: DISH_SOURCE_TYPE.WEBSITE,
};

export const newDishSourceRelationDetailOfRecipeWebsite = {
  recipeWebsiteUrl: 'https://youtube/ryuji/gyoza',
};

export const updatedDishSourceRelation = {
  dishId: updatedDish.id,
  dishSourceId: registeredDishSource.id,
  dishSourceType: registeredDishSource.type,
  dishSourceRelationDetail: newDishSourceRelationDetailOfRecipeWebsite,
};


export const registerDishSourcesQuery = () => {
  registerQueryHandler(DishSourcesDocument, {
    dishSources: [
      registeredDishSource,
      registeredDishSource2,
    ].map((dishSource) => {
      return {
        __typename: 'DishRegisteredWithMeal',
        ...dishSource,
      };
    }),
  });
}
