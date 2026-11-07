import React from 'react';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import '@testing-library/jest-dom';
import MealFramePatternFields from './components/meal/frame/pattern/MealFramePatternFields';
import { LogicalHistoryProvider, useLogicalHistory } from './app/logical-history';
let mockPath = '/calendar/week/2026-10-27';
jest.mock('next/navigation', () => ({ usePathname: () => mockPath }));
jest.mock('./features/meal/frame/useMealFrame', () => ({__esModule:true, default:()=>({mealFrames:[{id:1,name:'one'}]})}));
it('submits NaN after choosing the placeholder again', async () => {
 const submit = jest.fn();
 render(<MealFramePatternFields defaultName="test" defaultDaySlots={[{entries:[{dayOffset:1,mealType:3,mealFrameId:1}]}]} submitLabel="save" submit={submit}/>);
 const user = userEvent.setup();
 await user.selectOptions(screen.getByTestId('mealFrame-0-0'), '--');
 await user.click(screen.getByTestId('submitMealFramePatternButton'));
 expect(submit).toHaveBeenCalled();
 expect(submit.mock.calls[0][1][0].mealFrameId).toBeNaN();
});
it('keeps old logical path after a Next pathname change', () => {
 Object.assign(window.location, {pathname: mockPath, search: ''});
 const Consumer = () => <p data-testid="path">{useLogicalHistory().currentPathAndQuery}</p>;
 const view = render(<LogicalHistoryProvider><Consumer/></LogicalHistoryProvider>);
 mockPath = '/calendar/month/2026-11-01';
 Object.assign(window.location, {pathname: mockPath, search: ''});
 view.rerender(<LogicalHistoryProvider><Consumer/></LogicalHistoryProvider>);
 expect(screen.getByTestId('path')).toHaveTextContent('/calendar/week/2026-10-27');
});
