export type SearchParams = Promise<{
  [key: string]: string | string[] | undefined;
}>;

export type NextPagePropsWithSearchParams = { searchParams: SearchParams };
