'use client';

import React from 'react';
import Link from 'next/link';
import { Button } from '../../components/ui/button';
import { ChevronLeft, Plus } from 'lucide-react';
import MealFrameList from '../../components/mealFrame/MealFrameList';

const MealFramesPage = () => {
  return (
    <div className="flex flex-col min-h-screen bg-background">
      <header className="sticky top-0 z-10 border-b bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60">
        <div className="mx-auto max-w-2xl px-4 py-3 flex items-center gap-3">
          <Link href="/calendar/week/thisweek" aria-label="カレンダーへ戻る">
            <Button variant="ghost" size="icon" className="size-8 shrink-0">
              <ChevronLeft className="size-4" />
            </Button>
          </Link>
          <h1 className="flex-1 text-base font-semibold">食事枠管理</h1>
          <Link href="/mealframes/new">
            <Button size="sm" className="gap-1.5 text-xs">
              <Plus className="size-3.5" />
              新規作成
            </Button>
          </Link>
        </div>
      </header>

      <main className="mx-auto w-full max-w-2xl flex-1 px-4 py-4">
        <MealFrameList />
      </main>
    </div>
  );
};

export default MealFramesPage;
