'use client';

import React, { useState } from 'react';
import { Button } from '@/components/ui/button';
import useMealFrame from '../../../../features/meal/frame/useMealFrame';
import type { UpdateMealFramePatternFunc } from '../../../../features/meal/frame/pattern/useMealFramePattern';

type PatternEntry = {
  id?: number;
  dayOffset: number;
  mealType: number;
  mealFrameId: number;
  mealFrameName?: string;
};

type Pattern = {
  id: number;
  name: string;
  entries: PatternEntry[];
};

type DaySlot = {
  entries: {
    dayOffset: number;
    mealType: number;
    mealFrameId: number;
  }[];
};

type Props = {
  pattern: Pattern;
  onSubmitSucceeded: () => void;
  updateMealFramePattern: UpdateMealFramePatternFunc;
};

const MEAL_TYPES = [
  { value: 1, label: '朝' },
  { value: 2, label: '昼' },
  { value: 3, label: '夜' },
];

const buildDaySlotsFromEntries = (entries: PatternEntry[]): DaySlot[] => {
  if (entries.length === 0) return [];

  const maxDay = Math.max(...entries.map((e) => e.dayOffset));
  const slots: DaySlot[] = Array.from({ length: maxDay }, () => ({ entries: [] }));

  entries.forEach((entry) => {
    slots[entry.dayOffset - 1].entries.push({
      dayOffset: entry.dayOffset,
      mealType: entry.mealType,
      mealFrameId: entry.mealFrameId,
    });
  });

  return slots;
};

export default ({ pattern, onSubmitSucceeded, updateMealFramePattern }: Props) => {
  const { mealFrames } = useMealFrame();

  const [name, setName] = useState(pattern.name);
  const [nameError, setNameError] = useState('');
  const [daySlots, setDaySlots] = useState<DaySlot[]>(() =>
    buildDaySlotsFromEntries(pattern.entries),
  );

  const addDaySlot = () => {
    setDaySlots([...daySlots, { entries: [] }]);
  };

  const removeDaySlot = (dayIndex: number) => {
    setDaySlots(daySlots.filter((_, i) => i !== dayIndex));
  };

  const addEntryToDay = (dayIndex: number) => {
    const firstMealFrame = mealFrames[0];
    const updated = daySlots.map((slot, i) => {
      if (i !== dayIndex) return slot;
      return {
        ...slot,
        entries: [
          ...slot.entries,
          {
            dayOffset: dayIndex + 1,
            mealType: MEAL_TYPES[0].value,
            mealFrameId: firstMealFrame?.id ?? 0,
          },
        ],
      };
    });
    setDaySlots(updated);
  };

  const removeEntryFromDay = (dayIndex: number, entryIndex: number) => {
    const updated = daySlots.map((slot, i) => {
      if (i !== dayIndex) return slot;
      return {
        ...slot,
        entries: slot.entries.filter((_, ei) => ei !== entryIndex),
      };
    });
    setDaySlots(updated);
  };

  const updateEntry = (
    dayIndex: number,
    entryIndex: number,
    field: 'mealType' | 'mealFrameId',
    value: number,
  ) => {
    const updated = daySlots.map((slot, i) => {
      if (i !== dayIndex) return slot;
      return {
        ...slot,
        entries: slot.entries.map((entry, ei) => {
          if (ei !== entryIndex) return entry;
          return { ...entry, [field]: value };
        }),
      };
    });
    setDaySlots(updated);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    if (!name.trim()) {
      setNameError('パターン名を入力してください。');
      return;
    }
    setNameError('');

    const entries = daySlots.flatMap((slot, dayIndex) =>
      slot.entries.map((entry) => ({
        dayOffset: dayIndex + 1,
        mealType: entry.mealType,
        mealFrameId: entry.mealFrameId,
      })),
    );

    await updateMealFramePattern(
      { mealFramePattern: { id: pattern.id, name, entries } },
      {
        onCompleted: () => {
          onSubmitSucceeded();
        },
      },
    );
  };

  return (
    <form onSubmit={handleSubmit}>
      <div>
        <label htmlFor="mealFramePatternName">パターン名</label>
        <input
          id="mealFramePatternName"
          data-testid="mealFramePatternName"
          value={name}
          onChange={(e) => setName(e.target.value)}
        />
        {nameError && <p>{nameError}</p>}
      </div>

      <div>
        {daySlots.map((slot, dayIndex) => (
          <div key={dayIndex} data-testid={`daySlot-${dayIndex}`}>
            <div>
              <span>{dayIndex + 1}日目</span>
              <button
                type="button"
                data-testid={`removeDaySlot-${dayIndex}`}
                onClick={() => removeDaySlot(dayIndex)}
              >
                日を削除
              </button>
            </div>

            <div>
              {slot.entries.map((entry, entryIndex) => (
                <div key={entryIndex} data-testid={`entry-${dayIndex}-${entryIndex}`}>
                  <select
                    data-testid={`mealType-${dayIndex}-${entryIndex}`}
                    value={entry.mealType}
                    onChange={(e) => updateEntry(dayIndex, entryIndex, 'mealType', Number(e.target.value))}
                  >
                    {MEAL_TYPES.map((mt) => (
                      <option key={mt.value} value={mt.value}>
                        {mt.label}
                      </option>
                    ))}
                  </select>

                  <select
                    data-testid={`mealFrame-${dayIndex}-${entryIndex}`}
                    value={entry.mealFrameId}
                    onChange={(e) => updateEntry(dayIndex, entryIndex, 'mealFrameId', Number(e.target.value))}
                  >
                    {mealFrames.map((frame) => (
                      <option key={frame.id} value={frame.id}>
                        {frame.name}
                      </option>
                    ))}
                  </select>

                  <button
                    type="button"
                    data-testid={`removeEntry-${dayIndex}-${entryIndex}`}
                    onClick={() => removeEntryFromDay(dayIndex, entryIndex)}
                  >
                    ×
                  </button>
                </div>
              ))}

              <button
                type="button"
                data-testid={`addEntryToDay-${dayIndex}`}
                onClick={() => addEntryToDay(dayIndex)}
              >
                + 枠を追加
              </button>
            </div>
          </div>
        ))}
      </div>

      <button
        type="button"
        data-testid="addDaySlotButton"
        onClick={addDaySlot}
      >
        + 日を追加
      </button>

      <Button type="submit" data-testid="submitMealFramePatternButton">
        更新する
      </Button>
    </form>
  );
};
