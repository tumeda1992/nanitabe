import React from 'react';
import DishSearchCard, { DishForSearchCard } from './index';
import { Button } from '../../ui/button';
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from '../../ui/dropdown-menu';
import { EllipsisVertical, Pencil, Trash2 } from 'lucide-react';

type DishSearchCardLibraryProps = {
  dish: DishForSearchCard;
  onEdit?: (dish: DishForSearchCard) => void;
  onDelete?: (dish: DishForSearchCard) => void;
  selected?: boolean;
  onToggle?: (dishId: number) => void;
};

const DishSearchCardLibrary = ({
  dish,
  onEdit,
  onDelete,
  selected,
  onToggle,
}: DishSearchCardLibraryProps) => {
  const showMenu = onEdit !== undefined || onDelete !== undefined;

  const actionMenu = (
    <div onClick={(e) => e.stopPropagation()}>
      <DropdownMenu>
        <DropdownMenuTrigger asChild>
          <Button
            variant="ghost"
            size="icon"
            className="size-8"
            aria-label="操作メニュー"
          >
            <EllipsisVertical className="size-4" />
          </Button>
        </DropdownMenuTrigger>
        <DropdownMenuContent align="end">
          {onEdit && (
            <DropdownMenuItem onClick={() => onEdit(dish)}>
              <Pencil className="size-4" />
              編集
            </DropdownMenuItem>
          )}
          {onDelete && (
            <DropdownMenuItem
              className="text-destructive focus:text-destructive"
              onClick={() => onDelete(dish)}
            >
              <Trash2 className="size-4" />
              削除
            </DropdownMenuItem>
          )}
        </DropdownMenuContent>
      </DropdownMenu>
    </div>
  );

  return (
    <div className="flex items-center gap-2">
      {/* チェックボックス (page モードのみ) */}
      {onToggle && (
        <button
          type="button"
          onClick={() => onToggle(dish.id)}
          aria-label={selected ? '選択解除' : '選択'}
          className="shrink-0 mt-3 self-start"
        >
          <div
            className={`flex size-5 items-center justify-center rounded border-2 transition-colors ${
              selected
                ? 'border-primary bg-primary text-primary-foreground'
                : 'border-muted-foreground/30'
            }`}
          >
            {selected && (
              <svg viewBox="0 0 12 12" className="size-3 fill-current">
                <path
                  d="M10 3L5 8.5 2 5.5"
                  stroke="currentColor"
                  strokeWidth="2"
                  fill="none"
                  strokeLinecap="round"
                  strokeLinejoin="round"
                />
              </svg>
            )}
          </div>
        </button>
      )}

      <div className="flex-1 min-w-0">
        <DishSearchCard
          dish={dish}
          selected={selected}
          onClick={onToggle ? () => onToggle(dish.id) : undefined}
          trailing={showMenu ? actionMenu : undefined}
        />
      </div>
    </div>
  );
};

export default DishSearchCardLibrary;
