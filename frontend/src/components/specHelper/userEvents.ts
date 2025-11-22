import { fireEvent, screen, waitFor } from '@testing-library/react';
import useEvent from '@testing-library/user-event';
// NOTE: クリックでコンポーネント内で非同期イベントがあったらその終了を待つ
import { act } from 'react-dom/test-utils';

export const user = useEvent.setup();

export const enterTextBox = (screen, testId, value) => {
  fireEvent.change(screen.getByTestId(testId), {
    target: { value },
  });
};

export const userClick = async (screen, elementTestId) => {
  await waitFor(() => screen.getByTestId(elementTestId));
  await user.click(screen.getByTestId(elementTestId));
};

export const userClearTextbox = async (screen, elementTestId) => {
  await waitFor(() => screen.getByTestId(elementTestId));
  await user.clear(screen.getByTestId(elementTestId));
};

export const userType = async (screen, elementTestId, value) => {
  await waitFor(() => screen.getByTestId(elementTestId));
  await user.type(screen.getByTestId(elementTestId), value);
};

export const userTypeAfterClearTextBox = async (
  screen,
  elementTestId,
  value,
) => {
  await userClearTextbox(screen, elementTestId);
  await userType(screen, elementTestId, value);
};

export const userChooseSelectBox = async (
  screen,
  selectBoxTestId: string,
  optionTestIds: string[],
) => {
  await waitFor(() => screen.getByTestId(selectBoxTestId));
  const options = optionTestIds.map((optionTestId) =>
    screen.getByTestId(optionTestId),
  );
  await user.selectOptions(screen.getByTestId(selectBoxTestId), options);
};
