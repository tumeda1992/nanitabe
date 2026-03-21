import React from 'react';
import { Trash2 } from 'lucide-react';
import { FrameEntryForCalender } from '../../../../lib/graphql/generated/graphql';
import { MEAL_TYPE } from '../../../../features/meal/const';
import useMealFrame from '../../../../features/mealFrame/useMealFrame';

type FrameCardProps = {
  frameEntry: FrameEntryForCalender;
  onDeleted: () => void;
};

const mealTypeLabel: Record<number, string> = {
  [MEAL_TYPE.BREAKFAST]: '朝',
  [MEAL_TYPE.LUNCH]: '昼',
  [MEAL_TYPE.DINNER]: '夜',
};

const FrameCard = ({ frameEntry, onDeleted }: FrameCardProps) => {
  const label = mealTypeLabel[frameEntry.mealType] ?? '';
  const { removeMealFrameEntry } = useMealFrame({ requireFetchedData: false });

  const handleDelete = async () => {
    const confirmed = window.confirm('本当に削除してもよろしいですか？');
    if (!confirmed) return;
    await removeMealFrameEntry(
      { id: frameEntry.id },
      {
        onCompleted: () => {
          onDeleted();
        },
      },
    );
  };

  return (
    <div
      className="rounded-lg overflow-hidden border bg-muted/30 mb-1"
      data-testid={`frameCard-${frameEntry.id}`}
    >
      <div className="flex w-full">
        {/* 左端カラーバー（枠用の識別色） */}
        <div className="w-1 shrink-0 bg-violet-400" />

        <div className="flex-1 px-2 py-1.5 min-w-0">
          <div className="flex items-center gap-1">
            <span className="text-xs text-violet-600 shrink-0">枠</span>
            <span className="font-medium text-sm leading-snug flex-1 truncate text-muted-foreground">
              {frameEntry.mealFrameName}
            </span>
            {label && (
              <span className="text-[10px] font-bold shrink-0 px-1 rounded bg-muted text-muted-foreground">
                {label}
              </span>
            )}
            <button
              type="button"
              onClick={(e) => {
                e.stopPropagation();
                handleDelete();
              }}
              aria-label="枠エントリ削除"
              data-testid={`frameCard-deleteBtn-${frameEntry.id}`}
              className="inline-flex size-7 items-center justify-center rounded-md text-muted-foreground hover:text-destructive hover:bg-destructive/10 transition-colors [&>svg]:size-3 shrink-0"
            >
              <Trash2 />
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default FrameCard;
