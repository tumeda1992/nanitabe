import React from 'react';
import CategoryIcon from '../../calendar/calendarComponents/DishCard/CategoryIcon';

export type DishForSearchCard = {
  id: number;
  name: string;
  mealPosition: number;
  comment?: string | null;
  dishSourceName?: string | null;
  evaluationScore?: number | null;
};

type DishSearchCardProps = {
  dish: DishForSearchCard;
  trailing?: React.ReactNode;
  onClick?: () => void;
  selected?: boolean;
  className?: string;
};

const cn = (...classes: (string | undefined | false | null)[]) =>
  classes.filter(Boolean).join(' ');

const DishSearchCard = ({
  dish,
  trailing,
  onClick,
  selected,
  className,
}: DishSearchCardProps) => {
  return (
    <div
      role={onClick ? 'button' : undefined}
      tabIndex={onClick ? 0 : undefined}
      onClick={onClick}
      onKeyDown={
        onClick
          ? (e) => {
              if (e.key === 'Enter' || e.key === ' ') onClick();
            }
          : undefined
      }
      data-testid={`existingDish-${dish.id}`}
      className={cn(
        'group flex w-full items-start gap-3 py-3 px-1 text-left transition-colors',
        onClick && 'cursor-pointer hover:bg-accent/40',
        selected && 'bg-primary/5',
        className,
      )}
    >
      {/* メインコンテンツ */}
      <div className="flex-1 min-w-0 flex flex-col gap-1">
        {/* 1行目: 料理名 + カテゴリ */}
        <div className="flex items-center gap-1.5 flex-wrap">
          <span className="text-sm font-semibold leading-snug">{dish.name}</span>
          <CategoryIcon mealPosition={dish.mealPosition} />
        </div>

        {/* 2行目: レシピ元 + 評価 */}
        {(dish.dishSourceName || (dish.evaluationScore != null && dish.evaluationScore > 0)) && (
          <div className="flex items-center gap-3 flex-wrap text-xs text-muted-foreground">
            {dish.dishSourceName && (
              <span>{dish.dishSourceName}</span>
            )}
            {dish.evaluationScore != null && dish.evaluationScore > 0 && (
              <span>★{dish.evaluationScore}</span>
            )}
          </div>
        )}

        {/* コメント行 */}
        {dish.comment && (
          <p className="text-xs text-muted-foreground line-clamp-2 leading-relaxed">
            {dish.comment}
          </p>
        )}
      </div>

      {/* trailing スロット */}
      {trailing && (
        <div className="shrink-0 self-center">{trailing}</div>
      )}
    </div>
  );
};

export default DishSearchCard;
