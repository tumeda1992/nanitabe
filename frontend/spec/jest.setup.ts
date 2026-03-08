import server from '../src/lib/graphql/specHelper/mockServer';

beforeAll(() => server.listen());
afterEach(() => server.resetHandlers());
afterAll(() => server.close());

// vaul (Drawer) uses pointer capture APIs not available in JSDOM
if (typeof window !== 'undefined') {
  if (!window.HTMLElement.prototype.setPointerCapture) {
    window.HTMLElement.prototype.setPointerCapture = jest.fn();
  }
  if (!window.HTMLElement.prototype.releasePointerCapture) {
    window.HTMLElement.prototype.releasePointerCapture = jest.fn();
  }
  if (!window.HTMLElement.prototype.hasPointerCapture) {
    window.HTMLElement.prototype.hasPointerCapture = jest.fn(() => false);
  }
}

// vaul sets pointer-events: none on body when drawer closes; clean up after each test
afterEach(() => {
  document.body.style.pointerEvents = '';
});

const setDummyNavigation = () => {
  // jestでnavigation(window.location.href)が未定義なので、テスト用に仮の値を定義
  Object.defineProperty(window, 'location', {
    value: {
      href: 'http://example.com',
    },
  });
};

const setDummyDialog = () => {
  const confirmMock = jest.fn(() => true);
  window.confirm = confirmMock;

  const alertMock = jest.fn(() => true);
  window.alert = alertMock;
};

beforeEach(() => {
  setDummyNavigation();
  setDummyDialog();
});
