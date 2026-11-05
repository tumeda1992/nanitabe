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
  '/calendar/week/2024-02-29?view=all',
  '/calendar/month/2024-02-29',
])('uses today for missing or invalid path %s', (path) => {
  expect(calendarDateFromPath(path, '/calendar/week', now)).toEqual(
    new Date(2026, 9, 26, 9),
  );
});

it('preserves the format-only validation and unanchored matching', () => {
  expect(
    calendarDateFromPath(
      '/prefix/calendar/week/2024-02-30',
      '/calendar/week',
      now,
    ),
  ).toEqual(new Date('2024-02-30T09:00:00'));
});
