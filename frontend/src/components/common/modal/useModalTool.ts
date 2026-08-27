import * as React from 'react';

const useModalVisiblity = (initialVisibility, onClose) => {
  const [modalVisible, setModalVisible] = React.useState(
    initialVisibility || false,
  );

  const onCloseRef = React.useRef(onClose);
  // render中のref書き込みは禁止されているため、commit後のeffectで最新値へ更新する。
  // closeModalはevent handlerからのみ呼ばれるため、1render遅れの問題は起きない。
  React.useEffect(() => {
    onCloseRef.current = onClose;
  });

  const openModal = React.useCallback(() => {
    setModalVisible(true);
  }, []);
  const closeModal = React.useCallback(() => {
    setModalVisible(false);
    if (onCloseRef.current) onCloseRef.current();
  }, []);
  const toggleModal = React.useCallback(() => {
    setModalVisible((prevState) => !prevState);
  }, []);

  const openModalOnClick = React.useCallback((e) => {
    e.preventDefault();
    openModal();
  }, [openModal]);

  const closeModalOnClick = React.useCallback((e) => {
    e.preventDefault();
    closeModal();
  }, [closeModal]);

  const toggleModalOnClick = React.useCallback((e) => {
    e.preventDefault();
    toggleModal();
  }, [toggleModal]);

  return {
    modalVisible,
    openModal,
    closeModal,
    openModalOnClick,
    closeModalOnClick,
    toggleModalOnClick,
    toggleModal,
  };
};

const useModalRef = <
  ModalRefElement extends HTMLElement,
  ModalOpenerRef extends HTMLElement,
>(
  closeModal: () => void,
) => {
  const modalRef = React.useRef<ModalRefElement>(null);
  const modalOpenerRef = React.useRef<ModalOpenerRef>(null);

  React.useEffect(() => {
    const clickedInSpecifiedNode = (ref, mouseDownEvent) => {
      return !ref.current || ref.current.contains(mouseDownEvent.target);
    };
    const listener = (e) => {
      if (
        clickedInSpecifiedNode(modalRef, e) ||
        clickedInSpecifiedNode(modalOpenerRef, e)
      ) {
        return;
      }
      closeModal();
    };
    document.addEventListener('mousedown', listener);
    return () => {
      document.removeEventListener('mousedown', listener);
    };
  }, [modalRef]);

  return {
    modalRef,
    modalOpenerRef,
  };
};

export type UseModalToolArgs = {
  onClose?: () => void;
};

type Args = UseModalToolArgs & {
  initialVisibility?: boolean;
};

export default (args: Args = { initialVisibility: false }) => {
  const { initialVisibility, onClose } = args;
  const {
    modalVisible,
    openModal,
    closeModal,
    openModalOnClick,
    closeModalOnClick,
    toggleModalOnClick,
    toggleModal,
  } = useModalVisiblity(initialVisibility, onClose);

  return {
    modalVisible,
    useModalRef,
    openModal,
    closeModal,
    openModalOnClick,
    closeModalOnClick,
    toggleModalOnClick,
    toggleModal,
  };
};
