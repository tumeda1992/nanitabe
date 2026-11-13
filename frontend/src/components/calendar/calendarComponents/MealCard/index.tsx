import React, { useState } from 'react';
import {
  Pencil,
  Trash2,
  Type,
  Star,
  ArrowLeftRight,
  CalendarArrowUp,
  CalendarClock,
  UtensilsCrossed,
  MoreHorizontal,
  CopyPlus,
  Unlink,
} from 'lucide-react';
import { MealForCalender } from '../../../../lib/graphql/generated/graphql';
import { MEAL_TYPE } from '../../../../features/meal/const';
import useMeal from '../../../../features/meal/useMeal';
import useMealFrame from '../../../../features/meal/frame/useMealFrame';
import usePostponedMeal from '../../../../features/meal/postponed/usePostponedMeal';
import useFullScreenModal from '../../../common/modal/useFullScreenModal';
import { EditMeal } from '../../../meal/MealForm';
import EvaluateDish from '../../../dish/EvaluateDish';
import { EditDish } from '../../../dish/DishForm';
import CategoryIcon from './CategoryIcon';

type MealCardProps = {
  meal: MealForCalender;
  onChanged: () => Promise<void>;
  canAnythingExceptDisplayDishName: boolean;
  calendarModeChangers: any;
  startSwappingMealsMode: (date: Date) => void;
  isToday?: boolean;
};

type MealConfig = {
  label: string;
  mark: string;
  text: string;
};

const mealConfig: Record<number, MealConfig> = {
  [MEAL_TYPE.LUNCH]: {
    label: '昼',
    mark: 'bg-lunch/15',
    text: 'text-lunch-foreground',
  },
  [MEAL_TYPE.DINNER]: {
    label: '夜',
    mark: 'bg-dinner/15',
    text: 'text-dinner-foreground',
  },
  [MEAL_TYPE.BREAKFAST]: {
    label: '朝',
    mark: 'bg-breakfast/15',
    text: 'text-breakfast-foreground',
  },
};

const defaultMealConfig: MealConfig = {
  label: '',
  mark: 'bg-muted',
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
      className={`inline-flex size-11 items-center justify-center rounded-md transition-colors [&>svg]:size-5 ${
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
          : 'text-zinc-700 hover:bg-background hover:text-foreground'
      } ${disabled ? 'opacity-30 pointer-events-none' : ''}`}
    >
      <span className="[&>svg]:size-4">{icon}</span>
      <span>{label}</span>
    </button>
  );
};

const MealCard = ({
  meal,
  onChanged,
  canAnythingExceptDisplayDishName,
  calendarModeChangers,
  startSwappingMealsMode,
  isToday = false,
}: MealCardProps) => {
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
  const { postponeMeal } = usePostponedMeal({ requireFetchedData: false });

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

  const handlePostpone = async () => {
    setActionsOpen(false);
    await postponeMeal(
      { mealId: meal.id },
      {
        onCompleted: () => {
          onChanged();
        },
      },
    );
  };

  const handleCopyName = () => {
    const sourceName = dish?.dishSourceRelation?.sourceName;
    const copyText = sourceName ? `${sourceName}の${dish.name}` : dish.name;
    navigator.clipboard.writeText(copyText);
    setActionsOpen(false);
  };

  const dishSourceRelation = dish?.dishSourceRelation;
  const hasEvaluation =
    dish.evaluationScore != null && dish.evaluationScore > 0;
  const hasSource = !!dishSourceRelation?.sourceName;

  const sourceText = (() => {
    if (!dishSourceRelation?.sourceName) return null;
    const name = dishSourceRelation.sourceName;
    const page = dishSourceRelation.recipeBookPage;
    return page ? `${name} P${page}` : name;
  })();

  const showEvaluateButton = isToday && canAnythingExceptDisplayDishName;

  return (
    <>
      <div
        className="mb-1 cursor-pointer"
        data-testid={`mealCard-${meal.id}`}
        onClick={() => setActionsOpen(true)}
      >
        <div className="flex w-full items-start gap-2 pl-1">
          {/* 昼夜の印 */}
          <span
            className={`mt-1.5 flex size-[22px] shrink-0 items-center justify-center rounded-md text-[11px] font-bold ${cfg.mark} ${cfg.text}`}
          >
            {cfg.label}
          </span>

          <div className="flex-1 py-1.5 min-w-0">
            {/* 枠名ラベル（料理名の上に薄グレーで表示） */}
            {meal.mealFrameName && (
              <div
                className="text-[10px] text-muted-foreground truncate mb-0.5"
                data-testid={`mealCard-frameName-${meal.id}`}
              >
                {meal.mealFrameName}
              </div>
            )}

            {/* 1行目: 区分アイコン + 料理名 + 点数 */}
            <div className="flex items-start gap-1.5">
              <CategoryIcon
                mealPosition={dish.mealPosition}
                dishSourceType={dishSourceRelation?.type}
                className={`shrink-0 ${isToday ? 'mt-[7px]' : 'mt-[3px]'} ${cfg.text}`}
              />
              <span
                className={
                  isToday
                    ? 'min-w-0 flex-1 break-words text-xl font-bold leading-snug text-foreground'
                    : 'min-w-0 flex-1 break-words text-sm font-medium leading-snug text-foreground'
                }
              >
                {dish.name}
              </span>
              {!isToday && hasEvaluation && (
                <span
                  className="inline-flex items-center gap-0.5 text-xs text-amber-700 shrink-0"
                  data-testid={`mealCard-evaluation-${meal.id}`}
                >
                  <Star className="size-3 fill-current" />
                  {dish.evaluationScore}
                </span>
              )}
            </div>

            {/* レシピ元 */}
            {hasSource && (
              <div
                className="mt-0.5 text-xs text-zinc-700 break-words"
                data-testid={`mealCard-source-${meal.id}`}
              >
                {sourceText}
              </div>
            )}

            {/* 料理コメント */}
            {dish.comment && (
              <p className="mt-0.5 text-xs text-muted-foreground leading-snug">
                {dish.comment}
              </p>
            )}

            {/* 食事コメント */}
            {meal.comment && (
              <p className="mt-0.5 text-xs text-muted-foreground leading-snug">
                {meal.comment}
              </p>
            )}

            {/* 今日: 評価ボタン */}
            {showEvaluateButton && (
              <button
                type="button"
                aria-label="評価"
                className="mt-1.5 inline-flex h-11 items-center gap-1 rounded-lg border border-border bg-background px-3 text-sm font-medium text-foreground"
                onClick={(e) => {
                  e.stopPropagation();
                  EvaluateDishModal.openModal();
                }}
              >
                {hasEvaluation ? (
                  `★${dish.evaluationScore} 評価を変更`
                ) : (
                  <>
                    <Star className="size-4" />
                    評価する
                  </>
                )}
              </button>
            )}
          </div>

          {canAnythingExceptDisplayDishName && (
            <div className="shrink-0">
              <QuickBtn
                icon={<MoreHorizontal />}
                label="その他のアクション"
                onClick={() => setActionsOpen((v) => !v)}
                active={actionsOpen}
              />
            </div>
          )}
        </div>

      {/* アクション展開エリア */}
      {actionsOpen && (
        <div className="mb-2 rounded-lg bg-muted p-1">
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
              data-testid={`mealCard-moveBtn-${meal.id}`}
            />
            <ActionBtn
              icon={<ArrowLeftRight />}
              label="日付交換"
              onClick={() => {
                setActionsOpen(false);
                startSwappingMealsMode(new Date(meal.date));
              }}
              data-testid={`mealCard-swapBtn-${meal.id}`}
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
              icon={<CalendarClock />}
              label="延期"
              onClick={handlePostpone}
              data-testid={`mealCard-postponeBtn-${meal.id}`}
            />
            <ActionBtn
              icon={<Trash2 />}
              label="削除"
              onClick={handleRemove}
              danger
              data-testid={`mealCard-deleteBtn-${meal.id}`}
            />
          </div>
        </div>
      )}
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
    </>
  );
};

export default MealCard;
