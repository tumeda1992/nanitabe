import React from 'react';
import ClientPage from './page.client';

export default async ({
  params,
}: {
  params: Promise<{ dishSourceId: string }>;
}) => {
  const { dishSourceId } = await params;

  return <ClientPage dishSourceIdString={dishSourceId as string} />;
};
