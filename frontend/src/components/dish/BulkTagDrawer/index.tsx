'use client';

import React, { useState } from 'react';
import {
  Drawer,
  DrawerContent,
  DrawerHeader,
  DrawerTitle,
  DrawerDescription,
  DrawerFooter,
} from '../../ui/drawer';
import { Button } from '../../ui/button';
import { Input } from '../../ui/input';
import { useBulkAddTagToDishes } from '../../../features/dish/tag/bulkAddTagMutation';

type BulkTagDrawerProps = {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  dishIds: Set<number>;
  onCompleted?: () => void;
};

const BulkTagDrawer = ({
  open,
  onOpenChange,
  dishIds,
  onCompleted,
}: BulkTagDrawerProps) => {
  const [tagName, setTagName] = useState('');
  const { bulkAddTagToDishes } = useBulkAddTagToDishes();

  const handleOpenChange = (next: boolean) => {
    if (!next) {
      setTagName('');
    }
    onOpenChange(next);
  };

  const handleAdd = () => {
    if (!tagName.trim()) return;
    bulkAddTagToDishes(
      { dishIds: [...dishIds], tag: tagName },
      {
        onCompleted: () => {
          onOpenChange(false);
          if (onCompleted) onCompleted();
        },
      },
    );
  };

  return (
    // modal={false}: タッチデバイスで drawer が開いた直後に focus が外に移ると
    // vaul の onFocusOutside が Radix に close させてしまう問題を防ぐ。
    // modal=false にすると vaul が onFocusOutside/onPointerDownOutside で
    // e.preventDefault() を呼ぶため、外部イベントで閉じなくなる。
    // キャンセルボタンと追加後の自動クローズで明示的に閉じる設計。
    <Drawer open={open} onOpenChange={handleOpenChange} modal={false}>
      <DrawerContent>
        <DrawerHeader>
          <DrawerTitle>タグを一括で追加</DrawerTitle>
          <DrawerDescription>
            {dishIds.size}件の料理にタグを追加します
          </DrawerDescription>
        </DrawerHeader>

        <div className="px-4 pb-4 flex flex-col gap-3">
          <Input
            data-testid="bulkTagNameInput"
            placeholder="タグ名を入力"
            value={tagName}
            onChange={(e) => setTagName(e.target.value)}
            onKeyDown={(e) => {
              if (e.key === 'Enter') handleAdd();
            }}
          />
        </div>

        <DrawerFooter className="flex-row gap-2">
          <Button
            variant="outline"
            className="flex-1"
            onClick={() => onOpenChange(false)}
          >
            キャンセル
          </Button>
          <Button
            data-testid="bulkTagAddButton"
            className="flex-1"
            onClick={handleAdd}
            disabled={!tagName.trim()}
          >
            追加
          </Button>
        </DrawerFooter>
      </DrawerContent>
    </Drawer>
  );
};

export default BulkTagDrawer;
