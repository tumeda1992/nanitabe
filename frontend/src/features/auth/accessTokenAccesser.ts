import nookies from 'nookies';

const COOKIE_ACCESS_TOKEN_KEY_NAME = 'at';
const COOKIE_AUTH_CLIENT_KEY_NAME = 'client';
const COOKIE_AUTH_UID_KEY_NAME = 'uid';

export const getAccessToken = (nextJsContext = null): string | null => {
  const cookies = nookies.get(nextJsContext);
  return cookies[COOKIE_ACCESS_TOKEN_KEY_NAME] || null;
};

export const getAuth = (nextJsContext = null) => {
  const cookies = nookies.get(nextJsContext);
  return {
    accessToken: cookies[COOKIE_ACCESS_TOKEN_KEY_NAME] || null,
    client: cookies[COOKIE_AUTH_CLIENT_KEY_NAME] || null,
    uid: cookies[COOKIE_AUTH_UID_KEY_NAME] || null,
  };
};

export const setAccessToken = (
  accessToken: string,
  nextJsContext = null,
): void => {
  nookies.set(nextJsContext, COOKIE_ACCESS_TOKEN_KEY_NAME, accessToken, {
    maxAge: 30 * 24 * 60 * 60,
    path: '/',
  });
};

export const useAccessToken = (nextJsContext = null) => {
  const accessToken = getAccessToken(nextJsContext);
  return {
    accessToken,
    setAccessToken,
  };
};
