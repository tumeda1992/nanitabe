import React, { useEffect, useRef, useState } from 'react';

export default (
  changeTrigger: any = null,
): [number, React.MutableRefObject<HTMLDivElement>] => {
  const [height, setHeight] = useState(0);
  const measureTargetElementRef = useRef<HTMLDivElement>();
  useEffect(() => {
    if (
      measureTargetElementRef.current &&
      measureTargetElementRef.current.offsetHeight !== null
    ) {
      setHeight(measureTargetElementRef.current.offsetHeight);
    } else {
      setHeight(0);
    }
  }, [changeTrigger]);

  return [height, measureTargetElementRef];
};
