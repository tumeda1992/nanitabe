import React from 'react';
import DishSearchCard, { DishForSearchCard } from './index';
import { Check } from 'lucide-react';

const cn = (...classes: (string | undefined | false | null)[]) =>
  classes.filter(Boolean).join(' ');

type DishSearchCardPickerProps = {
  dish: DishForSearchCard;
  selected: boolean;
  onToggle: (dishId: number) => void;
};

const DishSearchCardPicker = ({
  dish,
  selected,
  onToggle,
}: DishSearchCardPickerProps) => {
  const checkmark = (
    <div
      className={cn(
        'flex size-5 items-center justify-center rounded-full border-2 transition-colors',
        selected
          ? 'border-primary bg-primary text-primary-foreground'
          : 'border-muted-foreground/30',
      )}
    >
      {selected && <Check className="size-3" />}
    </div>
  );

  return (
    <DishSearchCard
      dish={dish}
      selected={selected}
      onClick={() => onToggle(dish.id)}
      trailing={checkmark}
    />
  );
};

export default DishSearchCardPicker;
