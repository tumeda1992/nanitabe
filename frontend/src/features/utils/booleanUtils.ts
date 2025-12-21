export const parseBoolOrNull = (boolableValue: any): boolean | null => {
  // TODO: 様々な候補の配列を渡して、どれかに当てはまったらという形に変更
  if (boolableValue === 'true') return true;
  if (boolableValue === 'false') return false;
  return null;
};
