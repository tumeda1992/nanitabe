import { renderHook, act } from '@testing-library/react';
import { useApolloClient } from '../../lib/graphql/buildApolloClient';
import useRefreshCalendarData from './useRefreshCalendarData';

jest.mock('../../lib/graphql/buildApolloClient', () => ({ useApolloClient: jest.fn() }));

const deferred = () => {
  let resolve!: () => void;
  let reject!: (error: Error) => void;
  const promise = new Promise<void>((yes, no) => { resolve = yes; reject = no; });
  void promise.catch(() => {});
  return { promise, resolve, reject };
};

it('waits for clearing and then calendar refetch before completing', async () => {
  const clearing = deferred();
  const fetching = deferred();
  const clearStore = jest.fn(() => clearing.promise);
  const refetch = jest.fn(() => fetching.promise);
  (useApolloClient as jest.Mock).mockReturnValue({ apolloClient: { clearStore } });
  const { result } = renderHook(() => useRefreshCalendarData({ refetchMealsForCalendar: refetch }));
  let completed = false;
  const pending = result.current.refreshData().then(() => { completed = true; });
  expect(clearStore).toHaveBeenCalledTimes(1);
  expect(refetch).not.toHaveBeenCalled();
  await act(async () => { clearing.resolve(); });
  expect(refetch).toHaveBeenCalledTimes(1);
  expect(completed).toBe(false);
  await act(async () => { fetching.resolve(); await pending; });
  expect(completed).toBe(true);
});

it('propagates a failed calendar refetch to the caller', async () => {
  const fetching = deferred();
  (useApolloClient as jest.Mock).mockReturnValue({ apolloClient: { clearStore: jest.fn().mockResolvedValue(undefined) } });
  const refetch = jest.fn(() => fetching.promise);
  const { result } = renderHook(() => useRefreshCalendarData({ refetchMealsForCalendar: refetch }));
  const pending = result.current.refreshData();
  const checked = expect(pending).rejects.toThrow('refetch failed');
  void checked.catch(() => {});
  await act(async () => { await Promise.resolve(); fetching.reject(new Error('refetch failed')); });
  await checked;
});

it('does not refetch if clearing the cache fails', async () => {
  const clearStore = jest.fn().mockRejectedValue(new Error('clear failed'));
  const refetch = jest.fn();
  (useApolloClient as jest.Mock).mockReturnValue({ apolloClient: { clearStore } });
  const { result } = renderHook(() => useRefreshCalendarData({ refetchMealsForCalendar: refetch }));
  await expect(result.current.refreshData()).rejects.toThrow('clear failed');
  expect(refetch).not.toHaveBeenCalled();
});
