const isExecInServerSide = typeof window === 'undefined';

// eslint-disable-next-line no-shadow
export enum ExecSituation {
  ExecInServerSide,
  ExecInClientSide,
}

export default isExecInServerSide
  ? ExecSituation.ExecInServerSide
  : ExecSituation.ExecInClientSide;