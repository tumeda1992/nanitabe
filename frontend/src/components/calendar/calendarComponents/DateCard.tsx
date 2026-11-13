import React from 'react';
import { getDate, getDay, isSameDay } from 'date-fns';
import { FrameEntryForCalender, MealForCalender } from '../../../lib/graphql/generated/graphql';
import MealCard from './MealCard';
import FrameCard from './FrameCard';
import AddMealIcon from './MealIcon/AddMealIcon';
import { buildISODateString } from '../../../features/utils/dateUtils';

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
    if (isSaturday) return 'text-blue-600';
    if (isSunday) return 'text-red-600';
    return '';
  })();
  const dayLabelColorClass = dateColorClass || 'text-muted-foreground';

  const hasMeals = meals && meals.length > 0;
  const hasFrames = frameEntries && frameEntries.length > 0;

  return (
    <div
      className={[
        'grid grid-cols-[52px_minmax(0,1fr)_44px] border-b border-border py-0.5',
        isToday ? 'bg-muted/50' : '',
      ]
        .filter(Boolean)
        .join(' ')}
      data-testid="dateCard-card"
      data-today={isToday ? 'true' : 'false'}
    >
      {/* 日付列 */}
      <button
        type="button"
        className="flex flex-col items-center gap-0.5 pt-1.5 self-start"
        data-testid="dateCard-dateHeader"
        onClick={() => startSwappingMealsMode(date)}
      >
        <span
          className={[
            'size-[26px] rounded-full flex items-center justify-center text-[15px] font-semibold',
            isToday ? 'bg-primary text-primary-foreground' : dateColorClass,
          ]
            .filter(Boolean)
            .join(' ')}
        >
          {dateNumber}
        </span>
        <span className={['text-xs', dayLabelColorClass].join(' ')}>
          {dayLabel}
        </span>
      </button>

      {/* 料理・枠一覧エリア */}
      <div className="min-w-0 py-1">
        {isToday && (
          <div
            className="px-1 text-xs font-semibold text-primary"
            data-testid="dateCard-todayLabel"
          >
            今日
          </div>
        )}
        {meals.map((meal) => (
          <React.Fragment key={meal.id}>
            <MealCard
              meal={meal}
              onChanged={async () => {
                await onChanged();
              }}
              canAnythingExceptDisplayDishName={isDisplayCalendarMode}
              calendarModeChangers={calendarModeChangers}
              startSwappingMealsMode={startSwappingMealsMode}
              isToday={isToday}
            />
          </React.Fragment>
        ))}

        {/* 枠エントリ一覧エリア */}
        {frameEntries && frameEntries.map((frameEntry) => (
          <React.Fragment key={`frame-${frameEntry.id}`}>
            <FrameCard
              frameEntry={frameEntry}
              unlinkedMeals={meals.filter((m) => !m.mealFrameEntryId)}
              date={buildISODateString(date)}
              canDelete={isDisplayCalendarMode}
              onDeleted={async () => {
                await onChanged();
              }}
              onAddSucceeded={async () => {
                await onChanged();
              }}
            />
          </React.Fragment>
        ))}

        {!hasMeals && !hasFrames && (
          <div
            className="px-1 py-2 text-sm text-muted-foreground"
            data-testid="dateCard-undecided"
          >
            未定
          </div>
        )}
      </div>

      {/* 追加ボタン列 */}
      <div className="flex justify-center items-start">
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
    </div>
  );
};
