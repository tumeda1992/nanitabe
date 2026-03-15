'use client';

import React, { useState } from 'react';
import Link from 'next/link';
import { Button } from '../../components/ui/button';
import DishSearchPanel from '../../components/dish/DishSearchPanel/index';
import DishSearchCardLibrary from '../../components/dish/DishSearchCard/Library';
import { type DishForSearchCard } from '../../components/dish/DishSearchCard/index';
import useDish from '../../features/dish/useDish';
import { ChevronLeft, Plus, Tag, Trash2, X } from 'lucide-react';
import BulkTagDrawer from '../../components/dish/BulkTagDrawer/index';
import useFullScreenModal from '../../components/common/modal/useFullScreenModal';
import { EditDish } from '../../components/dish/DishForm';

const cn = (...classes: (string | undefined | false | null)[]) =>
  classes.filter(Boolean).join(' ');

const DishesPageClient = () => {
  const [selectedIds, setSelectedIds] = useState<Set<number>>(new Set());
  const [bulkTagOpen, setBulkTagOpen] = useState(false);
  const [editingDishId, setEditingDishId] = useState<number | null>(null);

  const EditDishModal = useFullScreenModal({});

  const { removeDish } = useDish();

  const { dish: editingDish } = useDish({
    fetchDishesParams: {
      fetchDishParams: {
        requireFetchedData: !!editingDishId,
        condition: editingDishId ? { id: editingDishId } : undefined,
      },
    },
  });

  const handleToggle = (dishId: number) => {
    setSelectedIds((prev) => {
      const next = new Set(prev);
      if (next.has(dishId)) {
        next.delete(dishId);
      } else {
        next.add(dishId);
      }
      return next;
    });
  };

  const handleEdit = (dish: DishForSearchCard) => {
    setEditingDishId(dish.id);
    EditDishModal.openModal();
  };

  const handleDelete = (dish: DishForSearchCard) => {
    removeDish({ dishId: dish.id });
    setSelectedIds((prev) => {
      const next = new Set(prev);
      next.delete(dish.id);
      return next;
    });
  };

  const handleBulkDelete = async () => {
    for (const id of selectedIds) {
      await removeDish({ dishId: id });
    }
    setSelectedIds(new Set());
  };

  const hasSelection = selectedIds.size > 0;

  return (
    <>
      <div className="flex flex-col min-h-screen bg-background">
        {/* ヘッダー */}
        <header className="sticky top-0 z-10 border-b bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60">
          <div className="mx-auto max-w-2xl px-4 py-3 flex items-center gap-3">
            <Link href="/calendar/week/thisweek" aria-label="カレンダーへ戻る">
              <Button variant="ghost" size="icon" className="size-8 shrink-0">
                <ChevronLeft className="size-4" />
              </Button>
            </Link>
            <h1 className="flex-1 text-base font-semibold">料理検索</h1>
            <Link href="/dishes/new">
              <Button size="sm" className="gap-1.5 text-xs">
                <Plus className="size-3.5" />
                新規
              </Button>
            </Link>
          </div>
        </header>

        {/* メインコンテンツ */}
        <main
          className={cn(
            'mx-auto w-full max-w-2xl flex-1 px-4 py-4',
            hasSelection && 'pb-28',
          )}
        >
          <DishSearchPanel
            renderCard={(dish) => (
              <DishSearchCardLibrary
                dish={dish}
                selected={selectedIds.has(dish.id)}
                onToggle={handleToggle}
                onEdit={handleEdit}
                onDelete={handleDelete}
              />
            )}
          />
        </main>
      </div>

      <BulkTagDrawer
        open={bulkTagOpen}
        onOpenChange={setBulkTagOpen}
        dishIds={selectedIds}
        onCompleted={() => setSelectedIds(new Set())}
      />

      {editingDish && (
        <EditDishModal.FullScreenModal title="料理修正">
          <EditDish
            dish={editingDish}
            onEditSucceeded={() => {
              EditDishModal.closeModal();
              setEditingDishId(null);
            }}
          />
        </EditDishModal.FullScreenModal>
      )}

      {/* 一括アクション: フローティングバー (選択時のみ表示) */}
      <div
        className={cn(
          'fixed bottom-0 left-0 right-0 z-20 transition-transform duration-200 ease-out',
          hasSelection ? 'translate-y-0' : 'translate-y-full',
        )}
        aria-hidden={!hasSelection}
      >
        <div className="mx-auto max-w-2xl px-4 pb-6 pt-3">
          <div className="rounded-2xl border bg-background shadow-xl px-4 py-3 flex flex-col gap-2">
            {/* バー上部: 件数 + 選択解除 */}
            <div className="flex items-center justify-between">
              <span className="text-sm font-semibold">
                {selectedIds.size}件を選択中
              </span>
              <Button
                variant="ghost"
                size="sm"
                className="h-7 gap-1 text-xs"
                onClick={() => setSelectedIds(new Set())}
              >
                <X className="size-3.5" />
                選択解除
              </Button>
            </div>

            {/* アクションボタン群 */}
            <div className="flex flex-wrap gap-2">
              <Button
                variant="outline"
                size="sm"
                className="gap-1.5 text-xs flex-1"
                onClick={() => setBulkTagOpen(true)}
              >
                <Tag className="size-3.5" />
                タグを付ける
              </Button>
              <Button
                variant="destructive"
                size="sm"
                className="gap-1.5 text-xs flex-1"
                onClick={handleBulkDelete}
              >
                <Trash2 className="size-3.5" />
                削除
              </Button>
            </div>
          </div>
        </div>
      </div>
    </>
  );
};

export default DishesPageClient;
