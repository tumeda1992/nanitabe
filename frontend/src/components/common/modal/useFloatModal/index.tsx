import * as React from 'react';
import classnames from 'classnames';
import style from './FloatModal.module.scss';
import useModalTool, { UseModalToolArgs } from '../useModalTool';

type Args = UseModalToolArgs & {
  followRightEdge?: boolean;
};

export default (args: Args = {}) => {
  const { onClose, followRightEdge = false } = args;
  const {
    modalVisible,
    useModalRef,
    openModal,
    closeModal,
    openModalOnClick,
    closeModalOnClick,
    toggleModalOnClick,
    toggleModal,
  } = useModalTool();
  const { modalRef, modalOpenerRef } = useModalRef<
    HTMLDivElement,
    HTMLDivElement
  >(closeModal);

  const FloatModal = ({ children }: { children: React.ReactNode }) => (
    <div ref={modalRef} className={classnames(style['float-modal__wrapper'])}>
      {modalVisible && (
        <div
          className={classnames({
            [style['float-modal']]: true,
            [style['float-modal--follow-right-edge']]: followRightEdge,
          })}
        >
          {children}
        </div>
      )}
    </div>
  );
  const FloatModalOpener = ({ children }: { children: React.ReactNode }) => (
    <div
      ref={modalOpenerRef}
      onClick={toggleModalOnClick}
      className={classnames(style['float-modal-opener'])}
    >
      {children}
    </div>
  );

  return {
    FloatModal,
    FloatModalOpener,

    openModal,
    openModalOnClick,
    closeModal,
    closeModalOnClick,
    toggleModal,
    toggleModalOnClick,
  };
};
