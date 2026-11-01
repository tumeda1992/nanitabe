import { useAddMealFramePattern } from './addMealFramePatternMutation';
import { renderHook } from '@testing-library/react';
import {
  addMealFramePatternSchema,
  updateMealFramePatternSchema,
} from './schema';
import type { AddMealFramePatternInput } from './addMealFramePatternMutation';
import type { UpdateMealFramePatternInput } from './updateMealFramePatternMutation';

jest.mock('../../../utils/mutationUtils', () => ({
  buildMutationExecutor: jest.fn(() => [jest.fn(), false, undefined]),
}));

const entry = { dayOffset: 1, mealType: 2, mealFrameId: 3 };
const schema = addMealFramePatternSchema;
const parse = (body: unknown) => schema.safeParse({ mealFramePattern: body });

describe('pattern input schema contracts', () => {
  it('keeps entry order and strips unknown keys at every level', () => {
    expect(
      schema.parse({
        ignored: true,
        mealFramePattern: {
          id: 7,
          name: '週末',
          ignored: true,
          entries: [
            { ...entry, ignored: true },
            { ...entry, mealFrameId: 8 },
          ],
        },
      }),
    ).toEqual({
      mealFramePattern: {
        name: '週末',
        entries: [entry, { ...entry, mealFrameId: 8 }],
      },
    });
  });

  it('accepts an empty entry list', () => {
    expect(parse({ name: '週末', entries: [] }).success).toBe(true);
  });

  it('keeps the hook schema binding and the public inferred input types', () => {
    const { result } = renderHook(() => useAddMealFramePattern());
    expect(result.current.addMealFramePatternSchema).toBe(
      addMealFramePatternSchema,
    );
    const addInput: AddMealFramePatternInput = {
      mealFramePattern: { name: '週末', entries: [entry] },
    };
    const updateInput: UpdateMealFramePatternInput = {
      mealFramePattern: { ...addInput.mealFramePattern, id: 7 },
    };
    expect(updateMealFramePatternSchema.parse(updateInput)).toEqual(
      updateInput,
    );
    expect(updateMealFramePatternSchema.safeParse(addInput).success).toBe(
      false,
    );
  });

  it('keeps the update error order as id, name, entries', () => {
    const result = updateMealFramePatternSchema.safeParse({
      mealFramePattern: {},
    });
    expect(result.success).toBe(false);
    if (!result.success)
      expect(
        result.error.issues.map(({ path, code, message }) => ({
          path,
          code,
          message,
        })),
      ).toEqual([
        {
          path: ['mealFramePattern', 'id'],
          code: 'invalid_type',
          message: 'Required',
        },
        {
          path: ['mealFramePattern', 'name'],
          code: 'invalid_type',
          message: '必須項目です。',
        },
        {
          path: ['mealFramePattern', 'entries'],
          code: 'invalid_type',
          message: 'Required',
        },
      ]);
  });

  it.each([0, -1, 1.5])(
    'preserves the existing number contract for meal fields: %s',
    (number) => {
      expect(
        parse({
          name: '週末',
          entries: [{ dayOffset: 1.5, mealType: number, mealFrameId: number }],
        }).success,
      ).toBe(true);
    },
  );

  it.each([
    [
      { entries: [] },
      ['mealFramePattern', 'name'],
      'invalid_type',
      '必須項目です。',
    ],
    [
      { name: '', entries: [] },
      ['mealFramePattern', 'name'],
      'too_small',
      'パターン名を入力してください。',
    ],
    [
      { name: '週末', entries: [{ ...entry, dayOffset: 0 }] },
      ['mealFramePattern', 'entries', 0, 'dayOffset'],
      'too_small',
      '日数は1以上で指定してください。',
    ],
    [
      { name: '週末', entries: [{ ...entry, mealFrameId: '3' }] },
      ['mealFramePattern', 'entries', 0, 'mealFrameId'],
      'invalid_type',
      'Expected number, received string',
    ],
    [
      { name: '週末', entries: [{ ...entry, mealFrameId: NaN }] },
      ['mealFramePattern', 'entries', 0, 'mealFrameId'],
      'invalid_type',
      'Expected number, received nan',
    ],
    [
      { name: '週末' },
      ['mealFramePattern', 'entries'],
      'invalid_type',
      'Required',
    ],
  ])(
    'preserves error paths, codes and messages for %j',
    (body, path, code, message) => {
      const result = parse(body);
      expect(result.success).toBe(false);
      if (!result.success)
        expect(result.error.issues).toMatchObject([{ path, code, message }]);
    },
  );
});
