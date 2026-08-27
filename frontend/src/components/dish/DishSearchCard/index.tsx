import React from 'react';
import { CalendarDays, ChefHat } from 'lucide-react';
import CategoryIcon from '../../calendar/calendarComponents/MealCard/CategoryIcon';

export type DishForSearchCard = {
  id: number;
  name: string;
  mealPosition: number;
  comment?: string | null;
  dishSourceName?: string | null;
  evaluationScore?: number | null;
  effortLevelMinutes?: number | null;
  mealsCount?: number | null;
  lastCookedDate?: string | null;
};

const formatEffortTime = (minutes: number): string => {
  if (minutes < 60) return `${minutes}分`;
  const hours = Math.floor(minutes / 60);
  const remainingMinutes = minutes % 60;
  if (remainingMinutes === 0) return `${hours}時間`;
  return `${hours}時間${remainingMinutes}分`;
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

        {/* 2行目: レシピ元 + 評価 + 手間 */}
        {(dish.dishSourceName || (dish.evaluationScore != null && dish.evaluationScore > 0) || dish.effortLevelMinutes != null) && (
          <div className="flex items-center gap-3 flex-wrap text-xs text-muted-foreground">
            {dish.dishSourceName && (
              <span>{dish.dishSourceName}</span>
            )}
            {dish.evaluationScore != null && dish.evaluationScore > 0 && (
              <span>★{dish.evaluationScore}</span>
            )}
            {dish.effortLevelMinutes != null && (
              <span>🕐 {formatEffortTime(dish.effortLevelMinutes)}</span>
            )}
          </div>
        )}

        {/* 3行目: 最終調理日・調理回数 */}
        {(dish.mealsCount != null || dish.lastCookedDate != null) && (
          <div className="flex items-center gap-3 flex-wrap text-xs text-muted-foreground">
            <span className="flex items-center gap-1">
              <CalendarDays size={12} />
              {dish.lastCookedDate
                ? `最終 ${dish.lastCookedDate.split('-')[0]}/${parseInt(dish.lastCookedDate.split('-')[1], 10)}/${parseInt(dish.lastCookedDate.split('-')[2], 10)}`
                : '未調理'}
            </span>
            <span className="flex items-center gap-1">
              <ChefHat size={12} />
              {`${dish.mealsCount ?? 0}回`}
            </span>
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
