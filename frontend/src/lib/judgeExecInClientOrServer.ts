const isExecInServerSide = typeof window === 'undefined';

export enum ExecSituation {
  ExecInServerSide,
  ExecInClientSide,
}

export default isExecInServerSide
  ? ExecSituation.ExecInServerSide
  : ExecSituation.ExecInClientSide;
