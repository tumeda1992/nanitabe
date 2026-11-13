'use client';

import React from 'react';
import Link from 'next/link';
import {
  ChevronLeft,
  ChevronRight,
  CalendarRange,
  CalendarDays,
  EllipsisVertical,
  Utensils,
  CalendarClock,
} from 'lucide-react';
import { Button } from '@/components/ui/button';
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu';
import {
  WEEK_CALENDAR_PAGE_PATH_OF_THIS_WEEK,
  weekCalendarPagePathOf,
} from '@/app/calendar/week/[date]/consts';
import {
  MONTH_CALENDAR_PAGE_PATH_OF_THIS_MONTH,
  monthCalendarPagePathOf,
} from '@/app/calendar/month/[date]/consts';
import generateApiOrigin from '@/lib/generateApiOrigin';

type CalendarHeaderProps = {
  viewType: 'week' | 'month';
  displayLabel: string;
  currentDate: Date;
  refreshToPrev: () => void;
  refreshToNext: () => void;
  isDisplayCalendarMode: boolean;
  onStartAssigningDish: () => void;
  onStartPostponedMeal: () => void;
};

const CalendarHeader = ({
  viewType,
  displayLabel,
  currentDate,
  refreshToPrev,
  refreshToNext,
  isDisplayCalendarMode,
  onStartAssigningDish,
  onStartPostponedMeal,
}: CalendarHeaderProps) => {
  const isWeek = viewType === 'week';

  const todayHref = isWeek
    ? WEEK_CALENDAR_PAGE_PATH_OF_THIS_WEEK
    : MONTH_CALENDAR_PAGE_PATH_OF_THIS_MONTH;
  const weekViewHref = weekCalendarPagePathOf(currentDate);
  const monthViewHref = monthCalendarPagePathOf(currentDate);

  return (
    <header className="sticky top-0 z-10 border-b border-border bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60">
      <div className="mx-auto max-w-7xl px-1.5 py-1">
        <div className="flex items-center justify-between">
          {/* 左: 前後ナビ + 今週/今月ボタン */}
          <div className="flex items-center">
            <Button
              variant="ghost"
              size="icon"
              className="size-11"
              onClick={refreshToPrev}
              aria-label={isWeek ? '前の週' : '前の月'}
            >
              <ChevronLeft className="size-4" />
            </Button>
            <Button
              variant="ghost"
              size="sm"
              className="box-border h-11 min-w-11 px-1 text-xs font-medium"
              asChild
            >
              <Link href={todayHref} className="text-foreground no-underline">{isWeek ? '今週' : '今月'}</Link>
            </Button>
            <Button
              variant="ghost"
              size="icon"
              className="size-11"
              onClick={refreshToNext}
              aria-label={isWeek ? '次の週' : '次の月'}
            >
              <ChevronRight className="size-4" />
            </Button>
          </div>

          {/* 中央: 期間ラベル */}
          <span className="text-sm font-semibold text-foreground truncate">
            {displayLabel}
          </span>

          {/* 右: ビュー切替 + メニュー */}
          <div className="flex items-center">
            <Button
              variant={isWeek ? 'secondary' : 'ghost'}
              size="icon"
              className="size-11"
              asChild
              aria-label="週間ビュー"
            >
              <Link href={weekViewHref} className="text-foreground no-underline">
                <CalendarRange className="size-4" />
              </Link>
            </Button>
            <Button
              variant={!isWeek ? 'secondary' : 'ghost'}
              size="icon"
              className="size-11"
              asChild
              aria-label="月間ビュー"
            >
              <Link href={monthViewHref} className="text-foreground no-underline">
                <CalendarDays className="size-4" />
              </Link>
            </Button>

            <DropdownMenu>
              <DropdownMenuTrigger asChild>
                <Button
                  variant="ghost"
                  size="icon"
                  className="size-11"
                  aria-label="メニュー"
                  data-testid="calendarMenu"
                >
                  <EllipsisVertical className="size-4" />
                </Button>
              </DropdownMenuTrigger>
              <DropdownMenuContent align="end">
                {isDisplayCalendarMode && (
                  <DropdownMenuItem
                    onClick={onStartAssigningDish}
                    data-testid="calendarMenu-assignDish"
                  >
                    <Utensils className="size-4" />
                    食事割当て
                  </DropdownMenuItem>
                )}
                {isDisplayCalendarMode && (
                  <DropdownMenuItem
                    onClick={onStartPostponedMeal}
                    data-testid="calendarMenu-postponedMeal"
                  >
                    <CalendarClock className="size-4" />
                    延期した食事
                  </DropdownMenuItem>
                )}
                <DropdownMenuItem asChild>
                  <a
                    href={`${generateApiOrigin()}/admin/food/dish/word/normalize_words`}
                    target="_blank"
                    rel="noopener noreferrer"
                  >
                    (admin)ワード正規化
                  </a>
                </DropdownMenuItem>
                <DropdownMenuItem asChild>
                  <a href="/dishes">料理検索</a>
                </DropdownMenuItem>
                <DropdownMenuItem asChild>
                  <a href="/mealframes">食事枠管理</a>
                </DropdownMenuItem>
                <DropdownMenuItem asChild>
                  <a href="/mealframepatterns">食事枠パターン管理</a>
                </DropdownMenuItem>
              </DropdownMenuContent>
            </DropdownMenu>
          </div>
        </div>
      </div>
    </header>
  );
};

export default CalendarHeader;
