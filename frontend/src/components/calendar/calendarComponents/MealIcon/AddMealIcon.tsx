import React from 'react';
import { Plus } from 'lucide-react';
import useFullScreenModal from '../../../common/modal/useFullScreenModal';
import AddMealTabs from './AddMealTabs';
import { buildISODateString } from '../../../../features/utils/dateUtils';

type Props = {
  dateForAdd: Date;
  onAddSucceeded: () => void;
};

export default (props: Props) => {
  const { dateForAdd, onAddSucceeded } = props;
  const { FullScreenModal, FullScreenModalOpener, closeModal } =
    useFullScreenModal();

  const handleAddSucceeded = () => {
    closeModal();
    onAddSucceeded();
  };

  return (
    <>
      <FullScreenModalOpener>
        <div
          className="flex h-[52px] w-11 items-center justify-center cursor-pointer"
          data-testid="addMealIconOpener"
        >
          <span className="flex size-8 items-center justify-center rounded-lg bg-muted text-foreground">
            <Plus className="size-4" />
          </span>
        </div>
      </FullScreenModalOpener>
      <FullScreenModal title="食事登録">
        <AddMealTabs
          defaultDate={buildISODateString(dateForAdd)}
          onAddSucceeded={handleAddSucceeded}
        />
      </FullScreenModal>
    </>
  );
};
