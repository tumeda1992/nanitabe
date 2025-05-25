import { AddDishSource } from '../../../../features/dish/source/addDishSourceMutation';
import { UpdateDishSource } from '../../../../features/dish/source/updateDishSourceMutation';

export type AddOrUpdateDishSourceInput = AddDishSource | UpdateDishSource;
