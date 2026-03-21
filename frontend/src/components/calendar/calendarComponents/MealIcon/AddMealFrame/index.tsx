'use client';

import React, { useState } from 'react';
import { format } from 'date-fns';
import { Button } from '@/components/ui/button';
import useMealFrame from '../../../../../features/mealFrame/useMealFrame';

type Props = {
  dateForAdd: Date;
  onAddSucceeded: () => void;
};

const AddMealFrame = ({ dateForAdd, onAddSucceeded }: Props) => {
  const { mealFrames, addMealFrameEntry } = useMealFrame();
  const [selectedMealFrameId, setSelectedMealFrameId] = useState<number | null>(null);
  const [selectedMealType, setSelectedMealType] = useState<number | null>(null);

  const handleSubmit = async () => {
    if (!selectedMealFrameId || !selectedMealType) return;

    await addMealFrameEntry(
      {
        mealFrameEntry: {
          mealFrameId: selectedMealFrameId,
          date: format(dateForAdd, 'yyyy-MM-dd'),
          mealType: selectedMealType,
        },
      },
      {
        onCompleted: () => {
          onAddSucceeded();
        },
      },
    );
  };

  return (
    <div>
      <div>
        <label htmlFor="mealFrameSelect">食事枠</label>
        <select
          id="mealFrameSelect"
          data-testid="mealFrameSelect"
          value={selectedMealFrameId ?? ''}
          onChange={(e) => setSelectedMealFrameId(Number(e.target.value))}
        >
          <option value="">-- 枠を選択 --</option>
          {mealFrames.map((frame) => (
            <option key={frame.id} value={frame.id} data-testid={`mealFrameOption-${frame.id}`}>
              {frame.name}
            </option>
          ))}
        </select>
      </div>
      <div>
        <label htmlFor="mealTypeSelect">食事タイプ</label>
        <select
          id="mealTypeSelect"
          data-testid="mealTypeSelect"
          value={selectedMealType ?? ''}
          onChange={(e) => setSelectedMealType(Number(e.target.value))}
        >
          <option value="">-- タイプを選択 --</option>
          <option value="1" data-testid="mealTypeOption-1">朝食</option>
          <option value="2" data-testid="mealTypeOption-2">昼食</option>
          <option value="3" data-testid="mealTypeOption-3">夕食</option>
        </select>
      </div>
      <Button
        type="button"
        data-testid="submitAddMealFrameButton"
        onClick={handleSubmit}
        disabled={!selectedMealFrameId || !selectedMealType}
      >
        登録する
      </Button>
    </div>
  );
};

export default AddMealFrame;
