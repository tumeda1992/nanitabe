import React, { useState } from 'react';
import { parseISO } from 'date-fns';
import { Trash2 } from 'lucide-react';
import {
  FrameEntryForCalender,
  MealForCalender,
} from '../../../../lib/graphql/generated/graphql';
import { MEAL_TYPE } from '../../../../features/meal/const';
import useMealFrame from '../../../../features/meal/frame/useMealFrame';
import useFullScreenModal from '../../../common/modal/useFullScreenModal';
import { AddMeal } from '../../../meal/MealForm';

type FrameCardProps = {
  frameEntry: FrameEntryForCalender;
  unlinkedMeals?: MealForCalender[];
  onDeleted: () => void;
  onAddSucceeded?: () => void;
  date?: string;
};

const mealTypeLabel: Record<number, string> = {
  [MEAL_TYPE.BREAKFAST]: '朝',
  [MEAL_TYPE.LUNCH]: '昼',
  [MEAL_TYPE.DINNER]: '夜',
};

type TabType = 'new' | 'existing';

const FrameCard = ({
  frameEntry,
  unlinkedMeals = [],
  onDeleted,
  onAddSucceeded,
  date,
}: FrameCardProps) => {
  const label = mealTypeLabel[frameEntry.mealType] ?? '';
  const { removeMealFrameEntry, fillMealFrameEntry } = useMealFrame({
    requireFetchedData: false,
  });
  const { FullScreenModal, openModal, closeModal } = useFullScreenModal();
  const [activeTab, setActiveTab] = useState<TabType>('new');

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

  const handleCardClick = (e: React.MouseEvent) => {
    // 削除ボタンのクリックはモーダルを開かない
    if (
      (e.target as HTMLElement).closest(
        `[data-testid="frameCard-deleteBtn-${frameEntry.id}"]`,
      )
    ) {
      return;
    }
    setActiveTab('new');
    openModal();
  };

  const handleAddSucceeded = () => {
    closeModal();
    if (onAddSucceeded) onAddSucceeded();
  };

  const handleAssignMeal = async (mealId: number) => {
    await fillMealFrameEntry(
      { frameEntryId: frameEntry.id, mealId },
      {
        onCompleted: () => {
          closeModal();
          if (onAddSucceeded) onAddSucceeded();
        },
      },
    );
  };

  return (
    <>
      <div
        className="rounded-lg overflow-hidden border bg-muted/30 mb-1 cursor-pointer"
        data-testid={`frameCard-${frameEntry.id}`}
        onClick={handleCardClick}
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
      <FullScreenModal title="食事登録">
        <div>
          {/* タブ */}
          <div className="flex gap-2 mb-4 border-b">
            <button
              type="button"
              className={`pb-2 text-sm font-medium transition-colors ${
                activeTab === 'new'
                  ? 'border-b-2 border-primary text-primary'
                  : 'text-muted-foreground hover:text-foreground'
              }`}
              onClick={() => setActiveTab('new')}
            >
              新しく食事を登録
            </button>
            <button
              type="button"
              className={`pb-2 text-sm font-medium transition-colors ${
                activeTab === 'existing'
                  ? 'border-b-2 border-primary text-primary'
                  : 'text-muted-foreground hover:text-foreground'
              }`}
              onClick={() => setActiveTab('existing')}
            >
              既存の食事を割り当て
            </button>
          </div>

          {/* Tab 1: 新しく食事を登録 */}
          {activeTab === 'new' && (
            <div data-testid="addMealFormModal">
              <AddMeal
                frameEntryId={frameEntry.id}
                defaultDate={date ? parseISO(date) : undefined}
                onAddSucceeded={handleAddSucceeded}
              />
            </div>
          )}

          {/* Tab 2: 既存の食事を割り当て */}
          {activeTab === 'existing' && (
            <div>
              {unlinkedMeals.length === 0 ? (
                <p className="text-sm text-muted-foreground text-center py-8">
                  割り当て可能な食事がありません
                </p>
              ) : (
                <ul className="space-y-2">
                  {unlinkedMeals.map((meal) => (
                    <li key={meal.id}>
                      <button
                        type="button"
                        className="w-full text-left rounded-lg border p-3 text-sm hover:bg-muted/50 transition-colors"
                        onClick={() => handleAssignMeal(meal.id)}
                      >
                        {meal.dish.name}
                      </button>
                    </li>
                  ))}
                </ul>
              )}
            </div>
          )}
        </div>
      </FullScreenModal>
    </>
  );
};

export default FrameCard;
