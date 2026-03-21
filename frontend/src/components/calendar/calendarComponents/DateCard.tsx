import React from 'react';
import { getDate, getDay, isSameDay } from 'date-fns';
import { FrameEntryForCalender, MealForCalender } from '../../../lib/graphql/generated/graphql';
import DishCard from './DishCard';
import FrameCard from './FrameCard';
import AddMealIcon from './MealIcon/AddMealIcon';

type DateCardProps = {
  date: Date;
  dayLabel: string;
  meals: MealForCalender[];
  frameEntries: FrameEntryForCalender[];
  isDisplayCalendarMode: boolean;
  calendarModeChangers: any;
  onChanged: () => Promise<void>;
  startSwappingMealsMode: (date: Date) => void;
};

export default (props: DateCardProps) => {
  const {
    date,
    dayLabel,
    meals,
    frameEntries,
    isDisplayCalendarMode,
    calendarModeChangers,
    onChanged,
    startSwappingMealsMode,
  } = props;

  const isToday = isSameDay(date, new Date());
  const dayIndex = getDay(date);
  const dateNumber = getDate(date);

  const isSaturday = dayIndex === 6;
  const isSunday = dayIndex === 0;

  const dateColorClass = (() => {
    if (isSaturday) return 'text-blue-500';
    if (isSunday) return 'text-red-500';
    return '';
  })();

  const hasMeals = meals && meals.length > 0;

  return (
    <div
      className={[
        'rounded-xl border bg-card px-2.5 py-1.5',
        isToday ? 'ring-2 ring-primary/40' : '',
      ]
        .filter(Boolean)
        .join(' ')}
      data-testid="dateCard-card"
      data-today={isToday ? 'true' : 'false'}
    >
      {/* 日付ヘッダーエリア */}
      <div className="flex items-center justify-between mb-1">
        <button
          type="button"
          className="flex items-center gap-1"
          data-testid="dateCard-dateHeader"
          onClick={() => startSwappingMealsMode(date)}
        >
          <span
            className={[
              'size-6 rounded-full flex items-center justify-center text-xs font-medium',
              dateColorClass,
            ]
              .filter(Boolean)
              .join(' ')}
          >
            {dateNumber}
          </span>
          <span className={['text-xs', dateColorClass].filter(Boolean).join(' ')}>
            {dayLabel}
          </span>
        </button>

        {isDisplayCalendarMode && (
          <div data-testid="dateCard-addMeal">
            <AddMealIcon
              dateForAdd={date}
              onAddSucceeded={async () => {
                await onChanged();
              }}
            />
          </div>
        )}
      </div>

      {/* 料理一覧エリア */}
      <div>
        {hasMeals ? (
          meals.map((meal) => (
            <React.Fragment key={meal.id}>
              <DishCard
                meal={meal}
                onChanged={async () => {
                  await onChanged();
                }}
                canAnythingExceptDisplayDishName={isDisplayCalendarMode}
                calendarModeChangers={calendarModeChangers}
                startSwappingMealsMode={startSwappingMealsMode}
              />
            </React.Fragment>
          ))
        ) : isDisplayCalendarMode ? (
          <div
            className="border border-dashed rounded-lg p-2 text-center text-xs text-muted-foreground"
            data-testid="dateCard-emptyMealArea"
          />
        ) : null}

        {/* 枠エントリ一覧エリア */}
        {frameEntries && frameEntries.map((frameEntry) => (
          <React.Fragment key={`frame-${frameEntry.id}`}>
            <FrameCard
              frameEntry={frameEntry}
              onDeleted={async () => {
                await onChanged();
              }}
            />
          </React.Fragment>
        ))}
      </div>
    </div>
  );
};
