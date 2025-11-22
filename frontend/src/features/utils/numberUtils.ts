export const parseIntOrNull = (numberableValue: any): number | null => {
  if (numberableValue === undefined || numberableValue === null) return null;
  const parsedValue = Number(numberableValue);
  return Number.isNaN(parsedValue) ? null : parsedValue;
};
