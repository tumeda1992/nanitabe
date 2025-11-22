import * as React from 'react';

const useModalVisiblity = (initialVisibility, onClose) => {
  const [modalVisible, setModalVisible] = React.useState(
    initialVisibility || false,
  );

  const openModal = () => {
    setModalVisible(true);
  };
  const closeModal = () => {
    setModalVisible(false);
    if (onClose) onClose();
  };
  const toggleModal = () => {
    setModalVisible((prevState) => !prevState);
  };

  const openModalOnClick = (e) => {
    e.preventDefault();
    openModal();
  };

  const closeModalOnClick = (e) => {
    e.preventDefault();
    closeModal();
  };

  const toggleModalOnClick = (e) => {
    e.preventDefault();
    toggleModal();
  };

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
