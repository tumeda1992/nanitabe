import React from 'react';
import { act, fireEvent, render, screen } from '@testing-library/react';
import { LogicalHistoryProvider, useLogicalHistory } from './logical-history';

const realLocation = window.location;
let mockPathname = '/calendar/week/2025-02-03';
let mockSearch = '';
jest.mock('next/navigation', () => ({
  usePathname: () => mockPathname,
  useSearchParams: () => new URLSearchParams(mockSearch),
}));

const Consumer = () => {
  const { currentPathAndQuery, pushHistory } = useLogicalHistory();
  return <>
    <output data-testid="path">{currentPathAndQuery}</output>
    <button onClick={() => pushHistory('/calendar/week/2025-02-10?view=all#meal')}>advance</button>
  </>;
};
const tree = () => <LogicalHistoryProvider><Consumer /></LogicalHistoryProvider>;

beforeEach(() => {
  Object.defineProperty(window, 'location', { value: realLocation });
  mockPathname = '/calendar/week/2025-02-03';
  mockSearch = '';
  window.history.replaceState(null, '', mockPathname);
});
afterEach(() => jest.restoreAllMocks());

it('synchronizes a Next route change without adding another history entry', () => {
  const view = render(tree());
  const push = jest.spyOn(window.history, 'pushState');
  mockPathname = '/calendar/month/2025-02-03';
  mockSearch = 'view=all';
  window.history.replaceState(null, '', `${mockPathname}?${mockSearch}`);
  view.rerender(tree());
  expect(screen.getByTestId('path').textContent).toBe(`${mockPathname}?view=all`);
  expect(push).not.toHaveBeenCalled();
});

it('synchronizes query-only Next navigation', () => {
  const view = render(tree());
  mockSearch = 'view=all&tag=rice';
  window.history.replaceState(null, '', `${mockPathname}?${mockSearch}`);
  view.rerender(tree());
  expect(screen.getByTestId('path').textContent).toBe(`${mockPathname}?${mockSearch}`);
});

it('pushes once, excludes hash from logical state, and preserves logical navigation on rerender', () => {
  const view = render(tree());
  const push = jest.spyOn(window.history, 'pushState');
  fireEvent.click(screen.getByText('advance'));
  expect(push).toHaveBeenCalledTimes(1);
  expect(screen.getByTestId('path').textContent).toBe('/calendar/week/2025-02-10?view=all');
  expect(window.location.hash).toBe('#meal');
  view.rerender(tree());
  expect(screen.getByTestId('path').textContent).toBe('/calendar/week/2025-02-10?view=all');
  expect(push).toHaveBeenCalledTimes(1);
});

it('tracks popstate without pushing a new entry', () => {
  render(tree());
  const push = jest.spyOn(window.history, 'pushState');
  window.history.replaceState(null, '', '/calendar/month/2025-01-01?q=back');
  act(() => { window.dispatchEvent(new PopStateEvent('popstate')); });
  expect(screen.getByTestId('path').textContent).toBe('/calendar/month/2025-01-01?q=back');
  expect(push).not.toHaveBeenCalled();
});

it('reads the live browser URL when an earlier Next snapshot arrives after navigation', () => {
  const view = render(tree());
  mockPathname = '/calendar/month/2025-02-03';
  window.history.replaceState(null, '', '/calendar/week/2025-03-10?latest=true');
  view.rerender(tree());
  expect(screen.getByTestId('path').textContent).toBe('/calendar/week/2025-03-10?latest=true');
});
