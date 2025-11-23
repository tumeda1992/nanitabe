import React, { ReactNode } from 'react';
import classnames from 'classnames';
import useFloatModal from '../../../common/modal/useFloatModal';
import style from '../Calender/index.module.scss';

export default () => {
  const { FloatModal, FloatModalOpener, closeModal } = useFloatModal({
    followRightEdge: true,
  });

  const CalenderMenuWrapper: React.FC<{ children: ReactNode }> = ({
    children,
  }) => {
    return (
      <>
        <FloatModalOpener>
          <div className={style['mark__wrapper']}>
            <div
              className={classnames(
                'fa-solid fa-bars',
                style['mark'],
                style['mark-to-click'],
              )}
              data-testid="calenderMenu"
            />
          </div>
        </FloatModalOpener>
        <FloatModal>
          <ul className={classnames(style['calender-header-float-menu'])}>
            {children}
          </ul>
        </FloatModal>
      </>
    );
  };

  return {
    CalenderMenuWrapper,
    closeModal,
    calenderMenuStyle: style,
  };
};
