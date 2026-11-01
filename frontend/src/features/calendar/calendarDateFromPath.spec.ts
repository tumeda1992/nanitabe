import { calendarDateFromPath } from './calendarDateFromPath';

const now = new Date(2026, 9, 26, 17, 42);

it.each(['/calendar/week', '/calendar/month'])(
  'parses dates for %s at 09:00',
  (prefix) => {
    expect(calendarDateFromPath(`${prefix}/2024-02-29`, prefix, now)).toEqual(
      new Date(2024, 1, 29, 9),
    );
  },
);

it.each([
  '',
  '/calendar/week',
  '/calendar/week/not-a-date',
  '/calendar/month/2024-02-29',
])('uses today for missing or invalid path %s', (path) => {
  expect(calendarDateFromPath(path, '/calendar/week', now)).toEqual(
    new Date(2026, 9, 26, 9),
  );
});

it.each(['?view=all', '#meal', '?view=all#meal'])(
  'preserves a valid date with suffix %s', (suffix) => {
    expect(calendarDateFromPath(`/calendar/week/2024-02-29${suffix}`, '/calendar/week', now)).toEqual(new Date(2024, 1, 29, 9));
  },
);

it.each([
  '2025-02-29', '2024-02-30', '2024-04-31', '2024-00-01',
  '2024-13-01', '2024-01-00', '2024-01-40',
])('uses today for impossible calendar date %s', (date) => {
  expect(calendarDateFromPath(`/calendar/week/${date}`, '/calendar/week', now)).toEqual(new Date(2026, 9, 26, 9));
});

it.each([
  '/prefix/calendar/week/2024-02-29',
  '/calendar/week/2024-02-29/extra',
  '/calendar/week/2024-02-29/',
])('requires the exact calendar prefix and one date segment: %s', (path) => {
  expect(calendarDateFromPath(path, '/calendar/week', now)).toEqual(new Date(2026, 9, 26, 9));
});

it.each(['2000-02-29', '0099-12-31'])('keeps valid dates without the year 0-99 constructor offset: %s', (date) => {
  const parsed = calendarDateFromPath(`/calendar/week/${date}`, '/calendar/week', now);
  expect(parsed.getFullYear()).toBe(Number(date.slice(0, 4)));
  expect(parsed.getHours()).toBe(9);
});
