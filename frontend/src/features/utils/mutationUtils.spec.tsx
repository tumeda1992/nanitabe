import React from 'react';
import { act, renderHook, waitFor } from '@testing-library/react';
import { ApolloClient, ApolloError, ApolloLink, ApolloProvider, InMemoryCache, Observable, gql, useMutation } from '@apollo/client';
import * as generated from '../../lib/graphql/generated/graphql';
import { buildMutationExecutor } from './mutationUtils';
import { useAddMeal } from '../meal/addMealMutation';
import { useUpdateDish } from '../dish/updateDishMutation';

jest.mock('../../lib/graphql/generated/graphql', () => ({
  ...jest.requireActual('../../lib/graphql/generated/graphql'),
  useAddMealMutation: jest.fn(),
  useAddMealWithNewDishMutation: jest.fn(),
  useAddMealWithNewDishAndNewSourceMutation: jest.fn(),
  useUpdateDishMutation: jest.fn(),
  useUpdateDishWithNewSourceMutation: jest.fn(),
  useEvaluateDishMutation: jest.fn(),
}));

const document = gql`mutation save($value: Int!) { save(value: $value) { id } }`;
const useSave = () => useMutation<{ save: { id: number } }, { value: number }>(document);
const hookNames = ['useAddMealMutation', 'useAddMealWithNewDishMutation', 'useAddMealWithNewDishAndNewSourceMutation', 'useUpdateDishMutation', 'useUpdateDishWithNewSourceMutation', 'useEvaluateDishMutation'] as const;

beforeEach(() => {
  hookNames.forEach((name) => {
    (generated[name] as jest.Mock).mockReturnValue([jest.fn(), { loading: false, error: undefined }]);
  });
});
afterEach(() => jest.restoreAllMocks());

const setup = (normalizeInput?: (input: { value: number }) => { value: number }) => {
  let observer: any;
  let sentVariables: any;
  const client = new ApolloClient({
    cache: new InMemoryCache(),
    link: new ApolloLink((operation) => new Observable((sink) => {
      observer = sink;
      sentVariables = operation.variables;
    })),
  });
  const wrapper = ({ children }: { children: React.ReactNode }) => <ApolloProvider client={client}>{children}</ApolloProvider>;
  const hook = renderHook(() => buildMutationExecutor<{ value: number }, { save: { id: number } }>(useSave, { normalizeInput }), { wrapper });
  return { ...hook, observer: () => observer, variables: () => sentVariables };
};

it('exposes the real Apollo loading state until the mutation completes', async () => {
  const hook = setup();
  expect(hook.result.current[1]).toBe(false);
  let pending: Promise<any>;
  act(() => { pending = hook.result.current[0]({ value: 1 }, {}); });
  await waitFor(() => expect(hook.result.current[1]).toBe(true));
  await act(async () => {
    hook.observer().next({ data: { save: { id: 7 } } });
    hook.observer().complete();
    await pending;
  });
  expect(hook.result.current[1]).toBe(false);
  expect(hook.result.current[2]).toBeUndefined();
});

it('propagates the same Apollo error to the consumer and callback', async () => {
  jest.spyOn(console, 'error').mockImplementation(() => {});
  const hook = setup();
  const onError = jest.fn();
  let pending: Promise<any>;
  act(() => { pending = hook.result.current[0]({ value: 1 }, { onError }); });
  await act(async () => {
    hook.observer().error(new Error('network failed'));
    await pending;
  });
  expect(hook.result.current[2]).toBeInstanceOf(ApolloError);
  expect(hook.result.current[2]).toBe(onError.mock.calls[0][0]);
  expect(hook.result.current[1]).toBe(false);
});

it('preserves normalized variables and the completion callback', async () => {
  const hook = setup(({ value }) => ({ value: value + 1 }));
  const onCompleted = jest.fn();
  let pending: Promise<any>;
  act(() => { pending = hook.result.current[0]({ value: 1 }, { onCompleted }); });
  expect(hook.variables()).toEqual({ value: 2 });
  await act(async () => {
    hook.observer().next({ data: { save: { id: 7 } } });
    hook.observer().complete();
    await pending;
  });
  expect(onCompleted).toHaveBeenCalledWith({ save: { id: 7 } });
});

it.each(hookNames)('aggregates state from %s', (name) => {
  const error = new ApolloError({ errorMessage: name });
  (generated[name] as jest.Mock).mockReturnValue([jest.fn(), { loading: true, error }]);
  if (name.startsWith('useAddMeal')) {
    const { result } = renderHook(() => useAddMeal());
    expect(result.current.addMealLoading).toBe(true);
    expect(result.current.addMealError).toBe(error);
  } else {
    const { result } = renderHook(() => useUpdateDish());
    expect(result.current.updateDishLoading).toBe(true);
    expect(result.current.updateDishError).toBe(error);
  }
});

it('allows callers to omit optional mutation callbacks', async () => {
  const mutation = jest.fn().mockResolvedValue({ data: { save: { id: 7 } } });
  const [execute] = buildMutationExecutor<{ value: number }, { save: { id: number } }>(
    () => [mutation, { loading: false, error: undefined }] as any,
  );
  await expect(execute({ value: 1 })).resolves.toEqual({ data: { save: { id: 7 } } });
  expect(mutation).toHaveBeenCalledWith(expect.objectContaining({ variables: { value: 1 } }));
});
