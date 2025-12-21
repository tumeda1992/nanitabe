import server from '../src/lib/graphql/specHelper/mockServer';

beforeAll(() => server.listen());
afterEach(() => server.resetHandlers());
afterAll(() => server.close());

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
