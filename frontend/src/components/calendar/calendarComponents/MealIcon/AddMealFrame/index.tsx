'use client';

import React, { useState } from 'react';
import { format } from 'date-fns';
import { Button } from '@/components/ui/button';
import useMealFrame from '../../../../../features/mealFrame/useMealFrame';
import { MEAL_TYPE, MEAL_TYPE_LABELS, MEAL_TYPES } from '../../../../../features/meal/const';
import { AddMealFrameMutation } from '../../../../../lib/graphql/generated/graphql';

const NEW_FRAME_SENTINEL = '__new__';

type Props = {
  dateForAdd: Date;
  onAddSucceeded: () => void;
};

const AddMealFrame = ({ dateForAdd, onAddSucceeded }: Props) => {
  const { mealFrames, addMealFrameEntry, addMealFrame, refetchMealFrames } = useMealFrame();
  const [selectedMealFrameId, setSelectedMealFrameId] = useState<number | null>(null);
  const [selectedMealType, setSelectedMealType] = useState<number>(MEAL_TYPE.DINNER);
  const [isCreatingNew, setIsCreatingNew] = useState(false);
  const [newFrameName, setNewFrameName] = useState('');

  const handleSelectChange = (value: string) => {
    if (value === NEW_FRAME_SENTINEL) {
      setIsCreatingNew(true);
      setSelectedMealFrameId(null);
    } else {
      setIsCreatingNew(false);
      setSelectedMealFrameId(value ? Number(value) : null);
    }
  };

  const handleConfirmNewFrame = async () => {
    if (!newFrameName.trim()) return;

    await addMealFrame(
      { mealFrame: { name: newFrameName.trim() } },
      {
        onCompleted: (data: AddMealFrameMutation) => {
          const newId = data.addMealFrame?.mealFrameId;
          if (newId) {
            setSelectedMealFrameId(newId);
          }
          setIsCreatingNew(false);
          setNewFrameName('');
          refetchMealFrames();
        },
      },
    );
  };

  const handleSubmit = async () => {
    if (!selectedMealFrameId) return;

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
          value={isCreatingNew ? NEW_FRAME_SENTINEL : (selectedMealFrameId ?? '')}
          onChange={(e) => handleSelectChange(e.target.value)}
        >
          <option value="">-- 枠を選択 --</option>
          {mealFrames.map((frame) => (
            <option key={frame.id} value={frame.id} data-testid={`mealFrameOption-${frame.id}`}>
              {frame.name}
            </option>
          ))}
          <option value={NEW_FRAME_SENTINEL} data-testid="mealFrameNewOption">新規作成...</option>
        </select>
      </div>

      {isCreatingNew && (
        <div>
          <input
            type="text"
            value={newFrameName}
            onChange={(e) => setNewFrameName(e.target.value)}
            placeholder="枠の名前を入力"
            data-testid="newMealFrameNameInput"
          />
          <Button
            type="button"
            data-testid="confirmNewMealFrameButton"
            onClick={handleConfirmNewFrame}
          >
            確定
          </Button>
        </div>
      )}

      <div>
        <span>食事タイプ</span>
        {MEAL_TYPES.map((mealType) => (
          <span key={mealType} className="inline-flex items-center gap-1 mr-3">
            <input
              type="radio"
              name="mealType"
              value={mealType}
              checked={mealType === selectedMealType}
              onChange={() => setSelectedMealType(mealType)}
              id={`mealTypeRadio-${mealType}`}
              data-testid={`mealTypeRadio-${mealType}`}
            />
            <label htmlFor={`mealTypeRadio-${mealType}`}>{MEAL_TYPE_LABELS[mealType]}</label>
          </span>
        ))}
      </div>
      <Button
        type="button"
        data-testid="submitAddMealFrameButton"
        onClick={handleSubmit}
        disabled={!selectedMealFrameId}
      >
        登録する
      </Button>
    </div>
  );
};

export default AddMealFrame;
