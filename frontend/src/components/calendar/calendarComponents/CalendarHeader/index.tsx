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

type CalendarHeaderProps = {
  viewType: 'week' | 'month';
  displayLabel: string;
  currentDate: Date;
  refreshToPrev: () => void;
  refreshToNext: () => void;
  isDisplayCalendarMode: boolean;
  onStartAssigningDish: () => void;
};

const CalendarHeader = ({
  viewType,
  displayLabel,
  currentDate,
  refreshToPrev,
  refreshToNext,
  isDisplayCalendarMode,
  onStartAssigningDish,
}: CalendarHeaderProps) => {
  const isWeek = viewType === 'week';

  const todayHref = isWeek
    ? WEEK_CALENDAR_PAGE_PATH_OF_THIS_WEEK
    : MONTH_CALENDAR_PAGE_PATH_OF_THIS_MONTH;
  const weekViewHref = weekCalendarPagePathOf(currentDate);
  const monthViewHref = monthCalendarPagePathOf(currentDate);

  return (
    <header className="sticky top-0 z-10 border-b border-border bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60">
      <div className="mx-auto max-w-7xl px-3 py-2">
        <div className="flex items-center justify-between gap-2">
          {/* 左: 前後ナビ + 今週/今月ボタン */}
          <div className="flex items-center gap-0.5">
            <Button
              variant="ghost"
              size="icon"
              className="size-8"
              onClick={refreshToPrev}
              aria-label={isWeek ? '前の週' : '前の月'}
            >
              <ChevronLeft className="size-4" />
            </Button>
            <Button
              variant="ghost"
              size="sm"
              className="h-8 px-2 text-xs font-medium"
              asChild
            >
              <Link href={todayHref}>{isWeek ? '今週' : '今月'}</Link>
            </Button>
            <Button
              variant="ghost"
              size="icon"
              className="size-8"
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
          <div className="flex items-center gap-0.5">
            <Button
              variant={isWeek ? 'secondary' : 'ghost'}
              size="icon"
              className="size-8"
              asChild
              aria-label="週間ビュー"
            >
              <Link href={weekViewHref}>
                <CalendarRange className="size-4" />
              </Link>
            </Button>
            <Button
              variant={!isWeek ? 'secondary' : 'ghost'}
              size="icon"
              className="size-8"
              asChild
              aria-label="月間ビュー"
            >
              <Link href={monthViewHref}>
                <CalendarDays className="size-4" />
              </Link>
            </Button>

            <DropdownMenu>
              <DropdownMenuTrigger asChild>
                <Button
                  variant="ghost"
                  size="icon"
                  className="size-8"
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
                <DropdownMenuItem asChild>
                  <a
                    href="https://nanitabe_back.kibotsu.com/admin/food/dish/word/normalize_words"
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
