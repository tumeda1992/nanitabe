import React, { useState } from 'react';
import classnames from 'classnames';
import { Button, Form } from 'react-bootstrap';
import style from './index.module.scss';
import useDish from '../../../features/dish/useDish';

type Props = {
  dishId: number;
  score?: number | null;
  onEditSucceeded?: () => void;
};

enum StarStatus {
  ACTIVE = 1,
  HALF_ACTIVE = 2,
  INACTIVE = 3,
}

const Star = (props: {
  maxScore: number;
  currentScore: number;
  updateScore: any;
}) => {
  const { maxScore, currentScore, updateScore } = props;

  const status = (() => {
    if (currentScore <= maxScore - 1) return StarStatus.INACTIVE;
    if (currentScore >= maxScore) return StarStatus.ACTIVE;
    if (currentScore === maxScore - 0.5) return StarStatus.HALF_ACTIVE;
  })();
  const isActive = status === StarStatus.ACTIVE;
  const isInactive = status === StarStatus.INACTIVE;
  const isHalfActive = status === StarStatus.HALF_ACTIVE;

  return (
    <div className={style['star-container']}>
      <div className={style['star-floating-container']}>
        <div
          className={style['star-floating-half-click-target']}
          onClick={() => {
            updateScore(maxScore - 0.5);
          }}
        />
        <div
          className={style['star-floating-half-click-target']}
          onClick={() => {
            updateScore(maxScore);
          }}
        />
      </div>
      <i
        className={classnames({
          'fa-star': true,
          [style['star']]: true,
          fas: isActive || isHalfActive,
          far: isInactive,
          'fa-star-half-alt': isHalfActive,
        })}
      />
    </div>
  );
};

export default (props: Props) => {
  const { dishId, score: registeredDishScore, onEditSucceeded } = props;

  const initialScore = registeredDishScore || 3;
  const [currentScore, updateScore] = useState(initialScore);

  const { evaluateDish } = useDish();

  const submitHandler = () => {
    // TODO: 時間できたらテスト作成
    evaluateDish(
      { dishId, score: currentScore },
      {
        onCompleted: () => {
          if (onEditSucceeded) onEditSucceeded();
        },
      },
    );
  };

  return (
    <>
      <div className={style['stars-container']}>
        {[1, 2, 3, 4, 5].map((score) => (
          <Star
            key={score}
            maxScore={score}
            currentScore={currentScore}
            updateScore={updateScore}
          />
        ))}
      </div>
      <Form.Group>
        <Button
          type="submit"
          variant="light"
          data-testid="submitEvaluateDishButton"
          onClick={submitHandler}
        >
          登録
        </Button>
      </Form.Group>
    </>
  );
};
