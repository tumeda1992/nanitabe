import React from 'react';
import { MEAL_POSITION } from '../../../../features/dish/const';
import { DISH_SOURCE_TYPE } from '../../../../features/dish/source/const';

type CategoryIconProps = {
  mealPosition: number;
  dishSourceType?: number | null;
  className?: string;
};

const icons: Record<string, React.ReactNode> = {
  STAPLE_FOOD: (
    <svg viewBox="0 0 512 512" fill="currentColor">
      <path d="M176 56c0-13.3 10.7-24 24-24h48c13.3 0 24 10.7 24 24s-10.7 24-24 24h-48c-13.3 0-24-10.7-24-24zm24 48h48c13.3 0 24 10.7 24 24s-10.7 24-24 24h-48c-13.3 0-24-10.7-24-24s10.7-24 24-24zm88 24c0-13.3 10.7-24 24-24h48c13.3 0 24 10.7 24 24s-10.7 24-24 24h-48c-13.3 0-24-10.7-24-24zM56 176H456c13.3 0 24 10.7 24 24s-10.7 24-24 24H424v48c0 77.4-55 142-128 156.8V448h56c13.3 0 24 10.7 24 24s-10.7 24-24 24H160c-13.3 0-24-10.7-24-24s10.7-24 24-24h56v-19.2C143 414 88 349.4 88 272V224H56c-13.3 0-24-10.7-24-24s10.7-24 24-24z" />
    </svg>
  ),
  MAIN_DISH: (
    <svg viewBox="0 0 448 512" fill="currentColor">
      <path d="M416 0C400 0 288 32 288 176V288c0 35.3 28.7 64 64 64h32V480c0 17.7 14.3 32 32 32s32-14.3 32-32V352 240 32c0-17.7-14.3-32-32-32zM64 16C64 7.8 57.9 1 49.7 .1S34.2 4.6 32.4 12.5L2.1 148.8C.7 155.1 0 161.5 0 167.9c0 45.9 35.1 83.6 80 87.7V480c0 17.7 14.3 32 32 32s32-14.3 32-32V255.6c44.9-4.1 80-41.8 80-87.7c0-6.4-.7-12.8-2.1-19.1L191.6 12.5c-1.8-8-9.3-13.3-17.4-12.4S160 7.8 160 16V150.2c0 5.4-4.4 9.8-9.8 9.8c-5.1 0-9.3-3.9-9.8-9L127.9 14.6C127.2 6.3 120.3 0 112 0s-15.2 6.3-15.9 14.6L83.7 151c-.5 5.1-4.7 9-9.8 9c-5.4 0-9.8-4.4-9.8-9.8V16z" />
    </svg>
  ),
  SIDE_DISH: (
    <svg viewBox="0 0 512 512" fill="currentColor">
      <path d="M346.7 6C337.6 17 320 42.3 320 72c0 40 15.3 55.3 40 80s40 40 80 40c29.7 0 55-17.6 66-26.7c4-3.3 6-8.2 6-13.3s-2-10-6-13.2c-11.4-9.1-38.3-26.8-74-26.8c-32 0-40 8-40 8s8-8 8-40c0-35.7-17.7-62.6-26.8-74C370 2 365.1 0 360 0s-10 2-13.3 6zM244.6 136c-40 0-77.1 18.1-101.7 48.2l60.5 60.5c6.2 6.2 6.2 16.4 0 22.6s-16.4 6.2-22.6 0l-55.3-55.3 0 .1L2.2 477.9C-2 487-.1 497.8 7 505s17.9 9 27.1 4.8l134.7-62.4-52.1-52.1c-6.2-6.2-6.2-16.4 0-22.6s16.4-6.2 22.6 0L199.7 433l100.2-46.4c46.4-21.5 76.2-68 76.2-119.2C376 194.8 317.2 136 244.6 136z" />
    </svg>
  ),
  SOUP: (
    <svg viewBox="0 0 512 512" fill="currentColor">
      <path d="M64 352c0 35.3 28.7 64 64 64H384c35.3 0 64-28.7 64-64v-16H64v16zm368-64H80c-44.2 0-80 35.8-80 80v16c0 61.9 50.1 112 112 112H400c61.9 0 112-50.1 112-112V368c0-44.2-35.8-80-80-80zM112 0c-8.8 0-16 7.2-16 16v48c0 44.2 35.8 80 80 80h64v16c0 8.8 7.2 16 16 16s16-7.2 16-16V128c0-8.8-7.2-16-16-16s-16 7.2-16 16v16H176c-26.5 0-48-21.5-48-48V16c0-8.8-7.2-16-16-16zm96 0c-8.8 0-16 7.2-16 16v64c0 8.8 7.2 16 16 16s16-7.2 16-16V16c0-8.8-7.2-16-16-16zm96 0c-8.8 0-16 7.2-16 16v64c0 8.8 7.2 16 16 16s16-7.2 16-16V16c0-8.8-7.2-16-16-16z" />
    </svg>
  ),
  DESSERT: (
    <svg viewBox="0 0 448 512" fill="currentColor">
      <path d="M86.4 5.5L61.8 47.6C58 54.1 56 61.6 56 69.2V72c0 22.1 17.9 40 40 40s40-17.9 40-40V69.2c0-7.6-2-15-5.8-21.6L105.6 5.5C103.6 2.1 100 0 96 0s-7.6 2.1-9.6 5.5zm128 0L189.8 47.6c-3.8 6.5-5.8 14-5.8 21.6V72c0 22.1 17.9 40 40 40s40-17.9 40-40V69.2c0-7.6-2-15-5.8-21.6L233.6 5.5C231.6 2.1 228 0 224 0s-7.6 2.1-9.6 5.5zM342.4 5.5L317.8 47.6c-3.8 6.5-5.8 14-5.8 21.6V72c0 22.1 17.9 40 40 40s40-17.9 40-40V69.2c0-7.6-2-15-5.8-21.6L361.6 5.5C359.6 2.1 356 0 352 0s-7.6 2.1-9.6 5.5zM0 192c0-17.7 14.3-32 32-32H416c17.7 0 32 14.3 32 32V320c0 17.7-14.3 32-32 32H32c-17.7 0-32-14.3-32-32V192zM64 384H384v64c0 35.3-28.7 64-64 64H128c-35.3 0-64-28.7-64-64V384z" />
    </svg>
  ),
  RESTAURANT: (
    <svg viewBox="0 0 616 512" fill="currentColor">
      <path d="M602 118.6L537.1 15C531.3 5.7 521 0 510 0H106C95 0 84.7 5.7 78.9 15L14 118.6c-29.6 47.3 4.5 109.4 60 109.4c27.1 0 51.4-14.8 63.1-38.7c12.5 25.7 39 41.3 68.9 41.3c29.9 0 56.4-15.6 68.9-41.3c12.5 25.7 39 41.3 68.9 41.3c29.9 0 56.4-15.6 68.9-41.3c11.7 23.9 36 38.7 63.1 38.7c55.5 0 89.6-62.1 60-109.4zM80 384c0-8.8 7.2-16 16-16h64c8.8 0 16 7.2 16 16v96H80V384zm320 96H208V320c0-17.7 14.3-32 32-32H368c17.7 0 32 14.3 32 32V480zm48 0V384c0-8.8 7.2-16 16-16h64c8.8 0 16 7.2 16 16v96H448z" />
    </svg>
  ),
};

const colorMap: Record<string, string> = {
  STAPLE_FOOD: 'text-amber-600',
  MAIN_DISH: 'text-rose-600',
  SIDE_DISH: 'text-emerald-600',
  SOUP: 'text-sky-600',
  DESSERT: 'text-pink-500',
  RESTAURANT: 'text-violet-600',
};

const CategoryIcon = ({
  mealPosition,
  dishSourceType,
  className,
}: CategoryIconProps) => {
  const key = (() => {
    if (dishSourceType === DISH_SOURCE_TYPE.RESTAURANT) return 'RESTAURANT';
    switch (mealPosition) {
      case MEAL_POSITION.STAPLE_FOOD:
        return 'STAPLE_FOOD';
      case MEAL_POSITION.MAIN_DISH:
        return 'MAIN_DISH';
      case MEAL_POSITION.SIDE_DISH:
        return 'SIDE_DISH';
      case MEAL_POSITION.SOUP:
        return 'SOUP';
      case MEAL_POSITION.DESSERT:
        return 'DESSERT';
      default:
        return null;
    }
  })();

  if (!key) return null;

  const colorClass = colorMap[key];
  const icon = icons[key];

  return (
    <span
      className={`inline-flex items-center ${colorClass}${className ? ` ${className}` : ''}`}
    >
      <span className="size-3.5 shrink-0">{icon}</span>
    </span>
  );
};

export default CategoryIcon;
