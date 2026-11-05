const assert = require('node:assert/strict');
const fs = require('node:fs');
const z = require('zod');
const blocks = {"add": "const mealFramePatternEntrySchema = z.object({\n  dayOffset: z.number().min(1, '日数は1以上で指定してください。'),\n  mealType: z.number(),\n  mealFrameId: z.number(),\n});\n\nconst addMealFramePatternSchema = z.object({\n  mealFramePattern: z.object({\n    name: z\n      .string({\n        required_error: '必須項目です。',\n      })\n      .min(1, 'パターン名を入力してください。'),\n    entries: z.array(mealFramePatternEntrySchema),\n  }),\n});\n", "update": "const mealFramePatternEntrySchema = z.object({\n  dayOffset: z.number().min(1, '日数は1以上で指定してください。'),\n  mealType: z.number(),\n  mealFrameId: z.number(),\n});\n\nconst updateMealFramePatternSchema = z.object({\n  mealFramePattern: z.object({\n    id: z.number(),\n    name: z\n      .string({\n        required_error: '必須項目です。',\n      })\n      .min(1, 'パターン名を入力してください。'),\n    entries: z.array(mealFramePatternEntrySchema),\n  }),\n});\n"};
const baseline = {
  add: new Function('z', blocks.add + '; return addMealFramePatternSchema;')(z),
  update: new Function('z', blocks.update + '; return updateMealFramePatternSchema;')(z),
};
const currentSource = fs.readFileSync('src/features/meal/frame/pattern/schema.ts', 'utf8')
  .replace(/^import \* as z from 'zod';\s*/, '').replace(/export const /g, 'const ');
const current = new Function('z', currentSource + '; return { add: addMealFramePatternSchema, update: updateMealFramePatternSchema };')(z);
const normalize = (schema, value) => {
  const result = schema.safeParse(value);
  return result.success ? { success: true, data: result.data } : { success: false, issues: result.error.issues };
};
let comparisons = 0;
for (const mode of ['add', 'update']) {
  const body = () => ({ ...(mode === 'update' ? { id: 7 } : {}), name: '週末', entries: [{ dayOffset: 1, mealType: 2, mealFrameId: 3 }] });
  const cases = [undefined, null, {}, { mealFramePattern: undefined }, { mealFramePattern: null }, { mealFramePattern: {} }, { mealFramePattern: body() }];
  for (const value of [undefined, null, '', ' ', '有効']) cases.push({ mealFramePattern: { ...body(), name: value } });
  for (const value of [undefined, null, [], {}]) cases.push({ mealFramePattern: { ...body(), entries: value } });
  for (const field of ['dayOffset', 'mealType', 'mealFrameId']) {
    for (const value of [undefined, null, '', '3', NaN, Infinity, -Infinity, 0, -1, 1, 1.5]) {
      cases.push({ mealFramePattern: { ...body(), entries: [{ ...body().entries[0], [field]: value }] } });
    }
  }
  for (const id of [undefined, null, '', '7', NaN, Infinity, -Infinity, 0, -1, 1.5]) cases.push({ mealFramePattern: { ...body(), id } });
  cases.push({ ignored: true, mealFramePattern: { ...body(), ignored: true, entries: [{ ...body().entries[0], ignored: true }, { dayOffset: 2, mealType: 3, mealFrameId: 4 }] } });
  cases.forEach((value, index) => {
    assert.deepEqual(normalize(current[mode], value), normalize(baseline[mode], value), `${mode} case ${index}`);
    comparisons += 1;
  });
}
console.log(`d58c473 schema comparisons: ${comparisons} passed`);
