'use client';

import React, { useState, useCallback } from 'react';
import { Input } from '../../ui/input';
import DishSearchCardLibrary from '../DishSearchCard/Library';
import DishSearchCardPicker from '../DishSearchCard/Picker';
import { type DishForSearchCard } from '../DishSearchCard/index';
import useDish from '../../../features/dish/useDish';
import { MEAL_POSITION, MEAL_POSITION_LABELS } from '../../../features/dish/const';
import { Search } from 'lucide-react';

export type DishSearchPanelMode = 'page' | 'library' | 'picker';

type DishSearchPanelProps = {
  mode: DishSearchPanelMode;
  selectedDishId?: number | null;
  onSelect?: (dish: DishForSearchCard) => void;
  onEdit?: (dish: DishForSearchCard) => void;
  onDelete?: (dish: DishForSearchCard) => void;
  selectedIds?: Set<number>;
  onToggle?: (dishId: number) => void;
};

type MealPositionFilter = number | null;
type RelatedMealFilter = boolean | null;

const mealPositionFilters: { value: MealPositionFilter; label: string }[] = [
  { value: null, label: '指定なし' },
  { value: MEAL_POSITION.STAPLE_FOOD, label: MEAL_POSITION_LABELS[MEAL_POSITION.STAPLE_FOOD] },
  { value: MEAL_POSITION.MAIN_DISH, label: MEAL_POSITION_LABELS[MEAL_POSITION.MAIN_DISH] },
  { value: MEAL_POSITION.SIDE_DISH, label: MEAL_POSITION_LABELS[MEAL_POSITION.SIDE_DISH] },
  { value: MEAL_POSITION.SOUP, label: MEAL_POSITION_LABELS[MEAL_POSITION.SOUP] },
  { value: MEAL_POSITION.DESSERT, label: MEAL_POSITION_LABELS[MEAL_POSITION.DESSERT] },
  { value: MEAL_POSITION.OTHER, label: MEAL_POSITION_LABELS[MEAL_POSITION.OTHER] },
];

const relatedMealFilters: { value: string; label: string; boolValue: RelatedMealFilter }[] = [
  { value: '', label: '指定なし', boolValue: null },
  { value: 'true', label: '関連食事あり', boolValue: true },
  { value: 'false', label: '関連食事なし', boolValue: false },
];

let searchTimer: ReturnType<typeof setTimeout> | null = null;

const DishSearchPanel = ({
  mode,
  selectedDishId,
  onSelect,
  onEdit,
  onDelete,
  selectedIds = new Set(),
  onToggle,
}: DishSearchPanelProps) => {
  const [searchString, setSearchString] = useState('');
  const [mealPositionFilter, setMealPositionFilter] = useState<MealPositionFilter>(null);
  const [registeredWithMealFilter, setRegisteredWithMealFilter] = useState<RelatedMealFilter>(null);

  const { existingDishesForRegisteringWithMeal: dishes, fetchLoading } = useDish({
    fetchDishesParams: {
      fetchExistingDishesForRegisteringWithMealParams: {
        requireFetchedData: true,
        searchString: searchString || null,
        mealPosition: mealPositionFilter,
        registeredWithMeal: registeredWithMealFilter,
      },
    },
  });

  const handleSearchChange = useCallback((e: React.ChangeEvent<HTMLInputElement>) => {
    if (searchTimer !== null) clearTimeout(searchTimer);
    const value = e.target.value;
    searchTimer = setTimeout(() => {
      setSearchString(value);
    }, 400);
  }, []);

  const handleToggle = useCallback(
    (dishId: number) => {
      if ((mode === 'picker' || mode === 'library') && onSelect && dishes) {
        const dish = dishes.find((d) => d.id === dishId);
        if (dish) onSelect(dish as DishForSearchCard);
      } else if (onToggle) {
        onToggle(dishId);
      }
    },
    [mode, onSelect, dishes, onToggle],
  );

  const dishList = dishes || [];

  return (
    <div className="flex flex-col gap-4">
      {/* フィルタ: 料理の位置 */}
      <fieldset>
        <legend className="mb-2 text-xs font-semibold text-muted-foreground tracking-wide uppercase">
          料理の位置
        </legend>
        <div className="flex flex-wrap gap-x-5 gap-y-2">
          {mealPositionFilters.map((f) => (
            <label
              key={String(f.value)}
              className="flex items-center gap-1.5 cursor-pointer select-none"
            >
              <input
                type="radio"
                name="meal-position-filter"
                value={String(f.value)}
                checked={mealPositionFilter === f.value}
                onChange={() => setMealPositionFilter(f.value)}
                className="accent-primary"
              />
              <span className="text-sm">{f.label}</span>
            </label>
          ))}
        </div>
      </fieldset>

      {/* フィルタ: 関連食事 */}
      <fieldset>
        <legend className="mb-2 text-xs font-semibold text-muted-foreground tracking-wide uppercase">
          関連食事
        </legend>
        <div className="flex flex-wrap gap-x-5 gap-y-2">
          {relatedMealFilters.map((f) => (
            <label
              key={f.value}
              className="flex items-center gap-1.5 cursor-pointer select-none"
            >
              <input
                type="radio"
                name="related-meal-filter"
                value={f.value}
                checked={registeredWithMealFilter === f.boolValue}
                onChange={() => setRegisteredWithMealFilter(f.boolValue)}
                className="accent-primary"
              />
              <span className="text-sm">{f.label}</span>
            </label>
          ))}
        </div>
      </fieldset>

      {/* 検索ワード */}
      <div className="relative">
        <Search className="absolute left-3 top-1/2 -translate-y-1/2 size-4 text-muted-foreground pointer-events-none" />
        <Input
          placeholder="料理を検索できます"
          onChange={handleSearchChange}
          className="pl-9"
        />
      </div>

      {/* 件数 */}
      {dishList.length > 0 && (
        <p className="text-xs text-muted-foreground">
          {dishList.length} 件
        </p>
      )}

      {/* 結果リスト */}
      {!fetchLoading && dishList.length === 0 ? (
        <p className="text-sm text-muted-foreground text-center py-6">
          該当する料理がありません
        </p>
      ) : (
        <div className="flex flex-col divide-y divide-border">
          {dishList.map((dish) => {
            const dishForCard = dish as DishForSearchCard;
            if (mode === 'picker') {
              return (
                <DishSearchCardPicker
                  key={dish.id}
                  dish={dishForCard}
                  selected={selectedDishId === dish.id}
                  onToggle={handleToggle}
                />
              );
            }
            return (
              <DishSearchCardLibrary
                key={dish.id}
                dish={dishForCard}
                selected={
                  mode === 'page'
                    ? selectedIds.has(dish.id)
                    : mode === 'library'
                      ? selectedDishId === dish.id
                      : false
                }
                onToggle={
                  mode === 'page'
                    ? handleToggle
                    : mode === 'library' && onSelect
                      ? handleToggle
                      : undefined
                }
                onEdit={onEdit}
                onDelete={onDelete}
              />
            );
          })}
        </div>
      )}
    </div>
  );
};

export default DishSearchPanel;
