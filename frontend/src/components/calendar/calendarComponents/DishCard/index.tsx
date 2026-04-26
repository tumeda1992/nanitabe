import React, { useState } from 'react';
import {
  Pencil,
  Trash2,
  Type,
  Star,
  ArrowLeftRight,
  CalendarArrowUp,
  UtensilsCrossed,
  MoreHorizontal,
  CopyPlus,
  Unlink,
} from 'lucide-react';
import { MealForCalender } from '../../../../lib/graphql/generated/graphql';
import { MEAL_TYPE } from '../../../../features/meal/const';
import useMeal from '../../../../features/meal/useMeal';
import useMealFrame from '../../../../features/meal/frame/useMealFrame';
import useFullScreenModal from '../../../common/modal/useFullScreenModal';
import { EditMeal } from '../../../meal/MealForm';
import EvaluateDish from '../../../dish/EvaluateDish';
import { EditDish } from '../../../dish/DishForm';
import CategoryIcon from './CategoryIcon';

type DishCardProps = {
  meal: MealForCalender;
  onChanged: () => Promise<void>;
  canAnythingExceptDisplayDishName: boolean;
  calendarModeChangers: any;
  startSwappingMealsMode: (date: Date) => void;
};

type MealConfig = {
  label: string;
  bg: string;
  bar: string;
  text: string;
};

const mealConfig: Record<number, MealConfig> = {
  [MEAL_TYPE.LUNCH]: {
    label: '昼',
    bg: 'bg-lunch-bg',
    bar: 'bg-lunch',
    text: 'text-lunch-foreground',
  },
  [MEAL_TYPE.DINNER]: {
    label: '夜',
    bg: 'bg-dinner-bg',
    bar: 'bg-dinner',
    text: 'text-dinner-foreground',
  },
  [MEAL_TYPE.BREAKFAST]: {
    label: '朝',
    bg: 'bg-breakfast-bg',
    bar: 'bg-breakfast',
    text: 'text-breakfast-foreground',
  },
};

const defaultMealConfig: MealConfig = {
  label: '',
  bg: 'bg-card',
  bar: 'bg-muted',
  text: 'text-muted-foreground',
};

const QuickBtn = ({
  icon,
  label,
  onClick,
  active,
}: {
  icon: React.ReactNode;
  label: string;
  onClick: () => void;
  active?: boolean;
}) => {
  return (
    <button
      type="button"
      onClick={(e) => {
        e.stopPropagation();
        onClick();
      }}
      title={label}
      aria-label={label}
      className={`inline-flex size-7 items-center justify-center rounded-md transition-colors [&>svg]:size-3 ${
        active
          ? 'text-foreground'
          : 'text-muted-foreground hover:text-foreground hover:bg-black/5'
      }`}
    >
      {icon}
    </button>
  );
};

const ActionBtn = ({
  icon,
  label,
  onClick,
  disabled,
  danger,
}: {
  icon: React.ReactNode;
  label: string;
  onClick: () => void;
  disabled?: boolean;
  danger?: boolean;
}) => {
  return (
    <button
      type="button"
      onClick={(e) => {
        e.stopPropagation();
        onClick();
      }}
      disabled={disabled}
      className={`flex flex-col items-center justify-center gap-0.5 rounded-md py-2 transition-colors text-[10px] font-medium leading-none ${
        danger
          ? 'text-destructive hover:bg-destructive/10'
          : 'text-muted-foreground hover:bg-muted hover:text-foreground'
      } ${disabled ? 'opacity-30 pointer-events-none' : ''}`}
    >
      <span className="[&>svg]:size-4">{icon}</span>
      <span>{label}</span>
    </button>
  );
};

const DishCard = ({
  meal,
  onChanged,
  canAnythingExceptDisplayDishName,
  calendarModeChangers,
  startSwappingMealsMode,
}: DishCardProps) => {
  const { dish } = meal;
  const cfg = mealConfig[meal.mealType] ?? defaultMealConfig;
  const [actionsOpen, setActionsOpen] = useState(false);

  const EditMealModal = useFullScreenModal({
    onClose: () => {
      setActionsOpen(false);
    },
  });
  const EvaluateDishModal = useFullScreenModal({
    onClose: () => {
      setActionsOpen(false);
    },
  });
  const EditDishModal = useFullScreenModal({
    onClose: () => {
      setActionsOpen(false);
    },
  });

  const { removeMeal } = useMeal();
  const { unassignMealFromFrameEntry } = useMealFrame({ requireFetchedData: false });

  const handleUnassign = async () => {
    if (!meal.mealFrameEntryId) return;
    const confirmed = window.confirm('枠との紐付けを解除してもよろしいですか？');
    if (!confirmed) return;
    setActionsOpen(false);
    await unassignMealFromFrameEntry(
      { frameEntryId: meal.mealFrameEntryId },
      {
        onCompleted: () => {
          onChanged();
        },
      },
    );
  };

  const handleRemove = async () => {
    const confirmed = window.confirm('本当に削除してもよろしいですか？');
    if (!confirmed) return;
    setActionsOpen(false);
    await removeMeal(
      { mealId: meal.id },
      {
        onCompleted: () => {
          onChanged();
        },
      },
    );
  };

  const handleCopyName = () => {
    navigator.clipboard.writeText(dish.name);
    setActionsOpen(false);
  };

  const dishSourceRelation = dish?.dishSourceRelation;
  const hasEvaluation =
    dish.evaluationScore != null && dish.evaluationScore > 0;
  const hasSource = !!dishSourceRelation?.sourceName;
  const hasSecondRow = hasEvaluation || hasSource;

  const sourceText = (() => {
    if (!dishSourceRelation?.sourceName) return null;
    const name = dishSourceRelation.sourceName;
    const page = dishSourceRelation.recipeBookPage;
    const displayName = name.length <= 10 ? name : `${name.slice(0, 10)}…`;
    return page ? `${displayName} P${page}` : displayName;
  })();

  return (
    <div
      className={`rounded-lg overflow-hidden border ${cfg.bg} mb-1 cursor-pointer`}
      data-testid={`dishCard-${meal.id}`}
      onClick={() => setActionsOpen(true)}
    >
      <div className="flex w-full">
        {/* 左端カラーバー */}
        <div className={`w-1 shrink-0 ${cfg.bar}`} />

        <div className="flex-1 px-2 py-1.5 min-w-0">
          {/* 枠名ラベル（料理名の上に薄グレーで表示） */}
          {meal.mealFrameName && (
            <div
              className="text-[10px] text-muted-foreground truncate mb-0.5"
              data-testid={`dishCard-frameName-${meal.id}`}
            >
              {meal.mealFrameName}
            </div>
          )}

          {/* 1行目: カテゴリ + 料理名 + 昼夜ラベル + クイックアイコン */}
          <div className="flex items-center gap-1">
            <CategoryIcon
              mealPosition={dish.mealPosition}
              dishSourceType={dishSourceRelation?.type}
              className={`shrink-0 ${cfg.text}`}
            />
            <span className="font-medium text-sm leading-snug flex-1 truncate">
              {dish.name}
            </span>
            {cfg.label && (
              <span
                className={`text-[10px] font-bold shrink-0 px-1 rounded ${cfg.bg} ${cfg.text}`}
              >
                {cfg.label}
              </span>
            )}
            {/* クイックアイコン（常時表示） */}
            <div className="flex items-center shrink-0 -mr-1">
              <QuickBtn
                icon={<UtensilsCrossed />}
                label="食事編集"
                onClick={() => EditMealModal.openModal()}
              />
              <QuickBtn
                icon={
                  <Star
                    className={
                      hasEvaluation ? 'fill-amber-400 text-amber-400' : ''
                    }
                  />
                }
                label="評価"
                onClick={() => EvaluateDishModal.openModal()}
              />
              {canAnythingExceptDisplayDishName && (
                <QuickBtn
                  icon={<MoreHorizontal />}
                  label="その他のアクション"
                  onClick={() => setActionsOpen((v) => !v)}
                  active={actionsOpen}
                  data-testid={`dishCard-moreBtn-${meal.id}`}
                />
              )}
            </div>
          </div>

          {/* 2行目: 評価 + レシピ元 */}
          {hasSecondRow && (
            <div className="flex items-center gap-2 mt-0.5 text-xs text-muted-foreground">
              {hasEvaluation && (
                <span
                  className="inline-flex items-center gap-0.5 text-amber-500 shrink-0"
                  data-testid={`dishCard-evaluation-${meal.id}`}
                >
                  <Star className="size-3 fill-current" />
                  {dish.evaluationScore}
                </span>
              )}
              {hasSource && (
                <span
                  className="truncate"
                  data-testid={`dishCard-source-${meal.id}`}
                >
                  {sourceText}
                </span>
              )}
            </div>
          )}

          {/* 料理コメント */}
          {dish.comment && (
            <p className="mt-0.5 text-xs text-muted-foreground leading-snug line-clamp-2">
              {dish.comment}
            </p>
          )}

          {/* 食事コメント */}
          {meal.comment && (
            <p className="mt-0.5 text-xs text-muted-foreground/70 italic leading-snug">
              {meal.comment}
            </p>
          )}
        </div>
      </div>

      {/* フルスクリーンモーダル（常時レンダリング、表示制御は内部） */}
      <EditMealModal.FullScreenModal title="食事修正">
        <EditMeal
          meal={meal}
          onEditSucceeded={() => {
            EditMealModal.closeModal();
            onChanged();
          }}
        />
      </EditMealModal.FullScreenModal>
      <EvaluateDishModal.FullScreenModal title="食事評価">
        <EvaluateDish
          dishId={dish.id}
          score={dish.evaluationScore}
          onEditSucceeded={() => {
            EvaluateDishModal.closeModal();
            onChanged();
          }}
        />
      </EvaluateDishModal.FullScreenModal>
      <EditDishModal.FullScreenModal title="料理修正">
        <EditDish
          dish={dish}
          onEditSucceeded={() => {
            EditDishModal.closeModal();
            onChanged();
          }}
        />
      </EditDishModal.FullScreenModal>

      {/* アクション展開エリア */}
      {actionsOpen && (
        <div className="border-t border-border/30 bg-background/60 px-2 py-1.5">
          <div className="grid grid-cols-4 gap-0.5">
            <ActionBtn
              icon={<UtensilsCrossed />}
              label="食事編集"
              onClick={() => {
                setActionsOpen(false);
                EditMealModal.openModal();
              }}
              disabled={!canAnythingExceptDisplayDishName}
            />
            <ActionBtn
              icon={
                <Star
                  className={
                    hasEvaluation ? 'fill-amber-400 text-amber-400' : ''
                  }
                />
              }
              label="評価"
              onClick={() => {
                setActionsOpen(false);
                EvaluateDishModal.openModal();
              }}
            />
            <ActionBtn
              icon={<Pencil />}
              label="料理編集"
              onClick={() => {
                setActionsOpen(false);
                EditDishModal.openModal();
              }}
            />
            <ActionBtn
              icon={<Type />}
              label="名前コピー"
              onClick={handleCopyName}
            />
            <ActionBtn
              icon={<CalendarArrowUp />}
              label="他の日へ"
              onClick={() => {
                setActionsOpen(false);
                calendarModeChangers.startMovingDishMode(meal);
              }}
              data-testid={`dishCard-moveBtn-${meal.id}`}
            />
            <ActionBtn
              icon={<ArrowLeftRight />}
              label="日付交換"
              onClick={() => {
                setActionsOpen(false);
                startSwappingMealsMode(new Date(meal.date));
              }}
              data-testid={`dishCard-swapBtn-${meal.id}`}
            />
            <ActionBtn
              icon={<CopyPlus />}
              label="食事複製"
              onClick={() => {
                setActionsOpen(false);
              }}
              disabled
            />
            {meal.mealFrameEntryId != null && (
              <ActionBtn
                icon={<Unlink />}
                label="枠解除"
                onClick={handleUnassign}
              />
            )}
            <ActionBtn
              icon={<Trash2 />}
              label="削除"
              onClick={handleRemove}
              danger
              data-testid={`dishCard-deleteBtn-${meal.id}`}
            />
          </div>
        </div>
      )}
    </div>
  );
};

export default DishCard;
