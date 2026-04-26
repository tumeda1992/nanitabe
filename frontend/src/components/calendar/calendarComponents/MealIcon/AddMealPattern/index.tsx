'use client';

import React, { useState } from 'react';
import { format } from 'date-fns';
import { Button } from '@/components/ui/button';
import useMealFramePattern from '../../../../../features/meal/frame/pattern/useMealFramePattern';

type Props = {
  dateForAdd: Date;
  onAddSucceeded: () => void;
};

const AddMealPattern = ({ dateForAdd, onAddSucceeded }: Props) => {
  const { mealFramePatterns, fetchMealFramePatternsLoading, applyMealFramePattern } =
    useMealFramePattern();
  const [selectedPatternId, setSelectedPatternId] = useState<number | null>(null);
  const [startDate, setStartDate] = useState<string>(format(dateForAdd, 'yyyy-MM-dd'));

  const handleSubmit = async () => {
    if (!selectedPatternId || !startDate) return;

    await applyMealFramePattern(
      { patternId: selectedPatternId, startDate },
      {
        onCompleted: () => {
          onAddSucceeded();
        },
      },
    );
  };

  if (fetchMealFramePatternsLoading) {
    return <div>読み込み中...</div>;
  }

  return (
    <div>
      <div>
        <label htmlFor="patternSelect">パターン</label>
        <select
          id="patternSelect"
          data-testid="patternSelect"
          value={selectedPatternId ?? ''}
          onChange={(e) => setSelectedPatternId(e.target.value ? Number(e.target.value) : null)}
        >
          <option value="">-- パターンを選択 --</option>
          {mealFramePatterns.map((pattern) => (
            <option key={pattern.id} value={pattern.id} data-testid={`patternOption-${pattern.id}`}>
              {pattern.name}（{pattern.entries.length}件）
            </option>
          ))}
        </select>
      </div>

      <div>
        <label htmlFor="startDateInput">開始日</label>
        <input
          type="date"
          id="startDateInput"
          data-testid="startDateInput"
          value={startDate}
          onChange={(e) => setStartDate(e.target.value)}
        />
      </div>

      <Button
        type="button"
        data-testid="submitApplyPatternButton"
        onClick={handleSubmit}
        disabled={!selectedPatternId || !startDate}
      >
        適用する
      </Button>
    </div>
  );
};

export default AddMealPattern;
