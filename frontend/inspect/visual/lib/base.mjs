import { chromium } from 'playwright';

const BASE_URL = 'http://localhost:18100';

/**
 * headless ブラウザを起動してログイン済みのページを返す
 * @param {{ email: string, password: string }} credentials
 * @returns {{ browser, page }}
 */
export async function createLoggedInPage(credentials) {
  const browser = await chromium.launch({
    headless: true,
    args: ['--no-sandbox', '--disable-setuid-sandbox', '--disable-dev-shm-usage'],
  });
  const context = await browser.newContext({
    viewport: { width: 1920, height: 1080 },
    locale: 'ja-JP',
    timezoneId: 'Asia/Tokyo',
  });
  const page = await context.newPage();

  await page.goto(`${BASE_URL}/login`);
  await page.waitForLoadState('networkidle');
  await page.fill('input[type="email"]', credentials.email);
  await page.fill('input[type="password"]', credentials.password);
  await page.click('button[type="submit"]');
  await page.waitForLoadState('networkidle');

  return { browser, page };
}

export { BASE_URL };
