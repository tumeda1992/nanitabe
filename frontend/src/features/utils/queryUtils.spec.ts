import { renderHook } from '@testing-library/react';
import { useCodegenQuery } from './queryUtils';

describe('useCodegenQuery', () => {
  const mockQueryResult = {
    data: { someData: 'value' },
    previousData: { someData: 'old' },
    loading: false,
    error: undefined,
    refetch: jest.fn(),
  };

  let codegenQueryHook: jest.Mock;

  beforeEach(() => {
    codegenQueryHook = jest.fn().mockReturnValue(mockQueryResult);
  });

  describe('when requireFetchedData is true', () => {
    it('calls codegenQueryHook with skip=false', () => {
      renderHook(() =>
        useCodegenQuery(codegenQueryHook, true, { id: 1 }),
      );

      expect(codegenQueryHook).toHaveBeenCalledWith(
        expect.objectContaining({ skip: false }),
      );
    });

    it('returns data from codegenQueryHook', () => {
      const { result } = renderHook(() =>
        useCodegenQuery(codegenQueryHook, true, { id: 1 }),
      );

      expect(result.current.data).toEqual({ someData: 'value' });
      expect(result.current.previousData).toEqual({ someData: 'old' });
      expect(result.current.fetchLoading).toBe(false);
    });
  });

  describe('when requireFetchedData is false', () => {
    it('calls codegenQueryHook with skip=true', () => {
      renderHook(() =>
        useCodegenQuery(codegenQueryHook, false, { id: 1 }),
      );

      expect(codegenQueryHook).toHaveBeenCalledWith(
        expect.objectContaining({ skip: true }),
      );
    });

    it('returns data from codegenQueryHook', () => {
      const { result } = renderHook(() =>
        useCodegenQuery(codegenQueryHook, false, { id: 1 }),
      );

      expect(result.current.data).toEqual({ someData: 'value' });
    });
  });

  describe('when requireFetchedData defaults to true', () => {
    it('calls codegenQueryHook with skip=false when requireFetchedData is omitted', () => {
      renderHook(() =>
        useCodegenQuery(codegenQueryHook, undefined, {}),
      );

      expect(codegenQueryHook).toHaveBeenCalledWith(
        expect.objectContaining({ skip: false }),
      );
    });
  });
});
